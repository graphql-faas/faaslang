FaaSlang
--------

# FaaSlang

![FaaSlang Logo](https://raw.githubusercontent.com/graphql-faas/faaslang/gh-pages/images/faaslang-logo-small.png)

## 功能即服务语言

**0.3.x**, dated **February 12th, 2018**.
以下是最新的FaaSlang规范的工作草案，版本**0.3.x**，日期为**2018年2月12日**。

FaaSlang是一个简单的开放规范，旨在定义围绕FaaS（“无服务器”）函数，网关和客户端接口（来自任何语言/ SDK的请求）的语义和实现细节。它的设计目标是通过鼓励我们如何记录和与它们交互的简单约定来降低FaaS微服务的组织复杂性，包括类型安全机制。同样，GraphQL旨在为开发人员与嵌套关系（图形）数据的接口方式提供意见和规范，FaaSlang也为FaaS资源做同样的事情。

如果您使用符合FaaSlang的部署和API网关（例如，如https://stdlib.com所使用的那样），您将获得与无服务器功能的传统网关相比的以下优势：

- 标准呼叫约定（HTTP）
- 类型安全
- 强制文档
- 后台执行（立即返回响应，以工作方式运行逻辑）

而这仅仅是个开始。您正在寻找的所有好东西，如速率限制，身份验证等，都不是FaaSlang规范的一部分，但可以轻松添加到此存储库中提供的示例中。

# 目录

1. [介绍](#introduction)
1. [为何选择FaaSlang？](#why-faaslang)
1. [规范](#specification)
   1. [FaaSlang资源定义](#faaslang-resource-definition)
   1. [上下文定义](#context-definition)
   1. [参数](#parameters)
      1. [约束](#constraints)
      1. [类型](#types)
      1. [类型转换](#type-conversion)
      1. [空值](#nullability)
   1. [FaaSlang 资源请求](#faaslang-resource-requests)
      1. [上下文](#context)
      1. [错误](#errors)
         1. [客户端错误](#clienterror)
         1. [参数错误](#parametererror)
            1. [细节: 必填](#details-required)
            1. [细节: 必填](#details-invalid)
         1. [致命错误](#fatalerror)
         1. [运行时错误](#runtimeerror)
         1. [ValueError](#valueerror)
1. [FaaSlang 服务器和网关: 实现](#faaslang-server-and-gateway-implementation)
1. [致谢](#acknowledgements)


# 什么是FaaSlang?

简而言之，FaaSlang定义了“无服务器”功能部署和执行（API）网关的语义和规则，将以下的东西：

```javascript
// hello_world.js

/**
* My hello world function!
*/
module.exports = function (name = 'world', callback) {

  callback(null, `hello ${name}`);

};
```

转换为一个无限可扩展的Web API（使用“无服务器”提供程序），可以像这样通过HTTP调用（GET）：


```
https://myhost.com/username/servicename/hello_world?name=joe
```

或者像这样（POST）：

```json
{
  "name": "joe"
}
```

并给出这样的结果：

```json
"hello joe"
```

或者，当发生类型不匹配时（如`{"name":10}`）：

```json
{
  "error": {
    "type":"ParameterError"
    ...
  }
}
```

# 为什么选择FaaSlang?

“无服务器”领域正在快速增长，随着它的发展，跟上所需的工具链也是如此。每个基础架构提供商都有自己的标准和围绕FaaS做事的方式，以至于我们依赖于各个开发人员来挑选最佳的部署框架。

FaaSlang采用不同的方法，并提供API网关的规范（以及相当强大的，非供应商特定的Node.js实现），作为“锁定”您和您的团队成员部署方式的一种方式执行“无服务器”功能。

一个AWS Lambda函数的示例 **（A）** ;

```javascript
exports.handler = (event, context, callback) => {
  let myVar = event.myVar;
  let requiredVar = event.requiredVar;
  myVar = myVar === undefined ? 1 : myVar;
  callback(null, 'Hello from Lambda!');
};
```

或Microsoft Azure功能 **(B)**;

```javascript
module.exports = function (context, req) {
  let myVar = req.query.myVar || req.body && req.body.myVar;
  let requiredVar = req.query.requiredVar || req.body && req.body.requiredVar;
  myVar = myVar === undefined ? 1 : myVar;
  context.res = {body: 'Hello from Microsoft Azure!'};
  context.done();
}
```

FaaSlang定义了Node.js函数的模型;

```javascript
/**
* @param {Number} myVar A number
* @param {String} requiredVar must be a string!
* @returns {String}
*/
module.exports = (myVar = 1, requiredVar, context, callback) => {
  callback(null, 'Hello from FaaSlang-compliant service vendor.');
};
```

注释用作类型安全的语义定义的一部分（如果它们不能从默认值中推断出来），则可以专门定义期望的参数，并且您仍然有一个可选context对象，以实现更强大的执行（参数重载等）。 ）

以下是当前FaaS工作流程的样子：

![Current FaaS Workflow](https://raw.githubusercontent.com/graphql-faas/faaslang/gh-pages/images/current-faas-workflow.jpg)

这是启用FaaSlang的工作流程的样子。

![FaaSlang Workflow](https://raw.githubusercontent.com/graphql-faas/faaslang/gh-pages/images/faaslang-workflow.jpg)

FaaSlang是数以千计的FaaS部署的成果，覆盖成千上万的开发人员分布在众多云服务提供商，并且需要标准化我们组织和与这些功能通信的能力。

# 规范

## FaaSlang 资源定义

FaaSlang定义是一个`definition.json`遵守以下格式的文件

定这样的函数（文件名`my_function.js`）：

```javascript
/**
* This is my function, it likes the greek alphabet
* @param {String} alpha Some letters, I guess
* @param {Number} beta And a number
* @param {Boolean} gamma True or false?
* @returns {Object} some value
*/
module.exports = async function my_function (alpha, beta = 2, gamma, context) {
  /* your code */
};
```

你需要提供如下所示的函数定义：


```json
{
  "name": "my_function",
  "format": {
    "language": "nodejs",
    "async": true
  },
  "description": "This is my function, it likes the greek alphabet",
  "bg": {
    "mode": "info",
    "value": ""
  },
  "charge": 1,
  "context": null,
  "params": [
    {
      "name": "alpha",
      "type": "string",
      "description": "Some letters, I guess"
    },
    {
      "name": "beta",
      "type": "number",
      "defaultValue": 2,
      "description": "And a number"
    },
    {
      "name": "gamma",
      "type": "boolean",
      "description": "True or false?"
    }
  ],
  "returns": {
    "type": "object",
    "description": "some value"
  }
}
```

此定义是可扩展的，这意味着您可以向其添加其他字段，但必须遵守此模式。

定义必须实现以下字段;


| 字段 | 说明 |
| ----- | ---------- |
| name | A user-readable function name (used to execute the function), must match `/[A-Z][A-Z0-9_]*/i` |
| format | An object requiring a `language` field, along with any implementation details |
| description | A brief description of what the function does, can be empty (`""`) |
| bg | An object containing "mode" and "value" parameters specifying the behavior of function responses when executed in the background |
| charge | An integer between 0 and 100 defining the cost (arbitrary units) to run this function, charged to authenticated users |
| params | An array of `NamedParameter`s, representing function arguments
| returns | A `Parameter` without a `defaultValue` representing function return value |

## 上下文定义

如果函数不访问执行上下文详细信息，则应始终为null。如果它是一个对象，则表示该函数确实访问了上下文详细信息（即`remoteAddress`,http标头等 - 请参阅上下文）。

此对象不必为空，它可以包含特定于的详细信息; 例如，`"context": {"user": ["id", "email"]}`可以指示执行上下文专门访问经过身份验证的用户ID和电子邮件地址。

## 参数

参数具有以下格式;


| 字段 | 必须 |  说明 |
| ----- | -------- | ---------- |
| name | NamedParameter Only | The name of the Parameter, must match `/[A-Z][A-Z0-9_]*/i` |
| type | yes | A string representing a valid FaaSlang type |
| description | yes | A short description of the parameter, can be empty string (`""`) |
| defaultValue | no | Must match the specified type, **if not provided this parameter is required** |

### 约束

第一个参数永远不能是“对象”类型。这是为了确保所有语言实现中的通用调用（即支持参数重载）的请求一致性。

### 类型

由于FaaSlang旨在为多语言，因此使用它定义的函数必须具有强类型签名。并非所有类型都保证在每种语言中都以相同的方式使用，我们将继续定义每种语言应如何与FaaSlang类型接口的规范。目前，类型是JSON值的有限超集。

| 类型 | 说明 | 参考输入 (JSON) |
| ---- | ---------- | -------------- |
| boolean | True or False | `true` or `false` |
| string | Basic text or character strings | `"hello"`, `"GOODBYE!"` |
| number | Any double-precision [Floating Point](https://en.wikipedia.org/wiki/IEEE_floating_point) value | `2e+100`, `1.02`, `-5` |
| float | Alias for `number` | `2e+100`, `1.02`, `-5` |
| integer | Subset of `number`, integers between `-2^53 + 1` and `+2^53 - 1` (inclusive) | `0`, `-5`, `2000` |
| object | Any JSON-serializable Object | `{}`, `{"a":true}`, `{"hello":["world"]}` |
| object.http | An object representing an HTTP Response. Accepts `headers`, `body` and `statusCode` keys | `{"body": "Hello World"}`, `{"statusCode": 404, "body": "not found"}`, `{"headers": {"Content-Type": "image/png"}, "body": new Buffer(...)}` |
| array | Any JSON-serializable Array | `[]`, `[1, 2, 3]`, `[{"a":true}, null, 5]` |
| buffer | Raw binary octet (byte) data representing a file | `{"_bytes": [8, 255]}` or `{"_base64": "d2h5IGRpZCB5b3UgcGFyc2UgdGhpcz8/"}` |
| any | Any value mentioned above | `5`, `"hello"`, `[]` |

### 类型转换

`buffer`类型将自动转换为object类似` {"_bytes": []}`或匹配的单个键值对的任何类型`{"_base64": ""}`。

否则，提供给函数的参数应与其定义的类型匹配。通过查询参数通过HTTP发出的请求POST请求包含类型`application/x-www-form-urlencoded`将在可能的情况下自动从字符串转换为各自的预期类型(参考如下 [FaaSlang Resource Requests](#faaslang-resource-requests))

| 类型 | 转换规则 |
| ---- | --------------- |
| boolean | `"t"` and `"true"` become `true`, `"f"` and `"false"` become `false`, otherwise **do not convert** |
| string | No conversion |
| number | Determine float value, if NaN **do not convert**, otherwise convert |
| float | Determine float value, if NaN **do not convert**, otherwise convert |
| integer | Determine float value, if NaN **do not convert**, may fail integer type check if not in range |
| object | Parse as JSON, if invalid **do not convert**, object may fail type check (array, buffer) |
| object.http | Parse as JSON, if invalid **do not convert**, object may fail type check (array, buffer) |
| array | Parse as JSON, if invalid **do not convert**, object may fail type check (object, buffer) |
| buffer | Parse as JSON, if invalid **do not convert**, object may fail type check (object, array) |
| any | No conversion |

### 可空值

所有类型都可以为空，但只能通过`"defaultValue": null`在`NamedParameter`定义中设置来指定可空性。也就是说，如果提供了默认值，则该类型不再可以为空。

### 设置HTTP头

FaaSlang规范并非仅用于HTTP，但如果通过HTTP使用提供的回调方法，则传递给回调的`第三个参数应该是表示HTTP Header键值对的Object`。

例如，要返回类型为`image/png`... 的图像

```javascript
module.exports = (imageName, callback) => {

  // fetch image, returns a buffer
  let png = imageName === 'cat' ?
    fs.readFileSync(`/images/kitty.png`) :
    fs.readFileSync(`/images/no-image.png`);

  // Forces image/png over HTTP requests, default
  //  for buffer would otherwise be application/octet-stream
  return callback(null, png, {'Content-Type': 'image/png'});

};
```

只有在回调结束函数时才能使用第三个参数，即不能与异步函数一起使用。这可用于通过HTTP，设置缓存详细信息（E-Tag标头）等提供任何类型的内容。

## FaaSlang 资源请求

符合FaaSlang标准的请求`必须`完成以下步骤;

1. 确保资源定义在存储或加入时有效且符合要求。
1. 使用初始请求详细信息执行握手（即HTTP）
1. 接受Array，Object或url编码变量的字符串
1. 如果存在HTTP和查询参数，则查询参数用作URL编码变量
1. 如果存在HTTP POST和查询参数，拒绝请求尝试时指定POST的请求同时包含一个` ClientError`

1. If over HTTP POST, requests **must** include a `Content-Type` header or
   a `ClientError` is immediately returned
1. If over HTTP POST, `Content-Type` **must** be `application/json` for `Array`
   or `Object` data, or `application/x-www-form-urlencoded` for string data or
   a `ClientError` is immediately returned
1. If `application/x-www-form-urlencoded` values are provided (either via POST
   body or query parameters), convert types based on [Type Conversion](#type-conversion)
   and knowledge of the function definition and create an `Object`
1. If `Array`: Parameters will be checked for type consistency in the order of
   the definition `params`
1. If `Object`: Parameters will be checked for type consistency based on names
   of the definition `params`
1. If any inconsistencies are found, cease execution and immediately return a
   `ParameterError`
1. If a parameter has no defaultValue specified and is not provided, immediately
   return a `ParameterError`
1. Try to execute the function, if the function fails to parse or is not valid,
   immediately return a `FatalError`
1. If a function hits a specified timeout (execution time limit), immediately
   return a `FatalError`
1. If a function returns an error (via callback) or one is thrown and not caught,
   immediately return a `RuntimeError`
1. If function returns inconsistent response (does not match `returns` type),
   immediately return a `ValueError`
1. If no errors are encountered, return the value to the client
1. If over HTTP and `content-type` is not being overloaded (i.e. developer
   specified through a vendor-specific mechanism), return `buffer` type data as
   `application/octet-stream` and any other values as `application/json`.


接受Array，Object或url编码变量的字符串
如果存在HTTP和查询参数，则查询参数用作URL编码变量
如果存在HTTP POST和查询参数，请拒绝尝试使用a指定POST主体的请求 ClientError
如果通过HTTP POST，请求必须包含Content-Type标头或ClientError立即返回
如果通过HTTP POST，Content-Type 必须是application/jsonfor Array或Objectdata，或者application/x-www-form-urlencoded对于字符串数据或a ClientError立即返回
如果application/x-www-form-urlencoded提供了值（通过POST正文或查询参数），则根据类型转换和函数定义知识转换类型并创建Object
如果Array：将按定义的顺序检查参数的类型一致性params
如果Object：将根据定义的名称检查参数的类型一致性params
如果发现任何不一致，请停止执行并立即返回 ParameterError
如果参数未指定defaultValue且未提供，请立即返回a ParameterError
尝试执行该函数，如果函数无法解析或无效，请立即返回a FatalError
如果函数达到指定的超时（执行时间限制），则立即返回a FatalError
如果函数返回错误（通过回调）或者抛出一个并且未捕获，则立即返回a RuntimeError
如果函数返回不一致的响应（与returns类型不匹配），则立即返回aValueError
如果未遇到任何错误，请将值返回给客户端
如果通过HTTP并且content-type没有过载（即通过特定于供应商的机制指定开发人员），则返回buffer类型数据application/octet-stream和任何其他值application/json。

### Context

Every function intended to be consumed via FaaSlang has the option to specify
an *optional* magic `context` parameter that receives vendor-specific
information about the function execution context - for example, if consumed over
HTTP, header details. FaaSlang definitions must specify whether or not they
consume a `context` object. Context objects are extensible but **MUST** contain
the following fields;

| Field | Definition |
| ----- | ---------- |
| params | An `object` mapping called parameter names to their values |
| http | `null` if not accessed via http, otherwise an `object` |
| http.headers | If accessed via HTTP, an `object` containing header values |

### Errors

Errors returned by FaaSlang-compliant services must follow the following JSON
format:

```json
{
  "error": {
    "type": "ClientError",
    "message": "You know nothing, Jon Snow",
    "details": {}
  }
}
```

`details` is an optional object that can provide additional Parameter details.
Valid Error types are:

- `ClientError`
- `ParameterError`
- `FatalError`
- `RuntimeError`
- `ValueError`

#### ClientError

`ClientError`s are returned as a result of bad or malformed client data,
  including lack of authorization or a missing function (not found). If over
  HTTP, they **must** returns status codes in the range of `4xx`.

#### ParameterError

`ParameterError`s are a result of Parameters not passing type-safety checks,
  and **must** return status code `400` if over HTTP.

Parameter Errors **must** have the following format;

```json
{
  "error": {
    "type": "ParameterError",
    "message": "ParameterError",
    "details": {...}
  }
}
```

`"details"` should be an object mapping parameter names to their respective
validation (type-checking) errors. Currently, this specification defines
two classifications of a ParameterError for a parameter; *required* and
*invalid*. The format of `"details": {}` should follow this format;

##### Details: Required

```json
{
  "param_name": {
    "message": "((descriptive message stating parameter is required))",
    "required": true
  }
}
```

##### Details: Invalid

```json
{
  "param_name": {
    "message": "((descriptive message stating parameter is invalid))",
    "invalid": true,
    "expected": {
      "type": "number"
    },
    "actual": {
      "type": "string",
      "value": "hello world"
    }
  }
}
```

#### FatalError

`FatalError`s are a result of function mismanagement - either your function
  could not be loaded, executed, or it timed out. These **must** return status
  code `500` if over HTTP.

#### RuntimeError

`RuntimeError`s are a result of uncaught exceptions in your code as it runs,
  including errors you explicitly choose to throw (or send to clients via a
  callback, for example). These **must** return status code `403` if over
  HTTP.

#### ValueError

`ValueError`s are a result of your function returning an unexpected value
  based on FaaSlang type-safety mechanisms. These **must** return status code
  `502` if over HTTP.

`ValueError` looks like an *invalid* ParameterError, where the `details`
Object only ever contains a single key called `"returns"`. These are encountered
due to implementation issues on the part of the function developer.

```json
{
  "error": {
    "type": "ValueError",
    "message": "ValueError",
    "details": {
      "returns": {
        "message": "((descriptive message stating return value is invalid))",
        "invalid": true,
        "expected": {
          "type": "boolean"
        },
        "actual": {
          "type": "number",
          "value": 2017
        }
      }
    }
  }
}
```

# FaaSlang Server and Gateway: Implementation

A fully-compliant FaaSlang gateway (that just uses local function resources)
is available with this package, simply clone it and run `npm test` or look
at the `/tests` folder for more information.

The current FaaSlang specification is used in production by the FaaS
provider [StdLib](https://stdlib.com), and is available for local use with the
[StdLib CLI Package](https://github.com/stdlib/lib) which relies on this
repository as a dependency.

# Acknowledgements

The software contained within this repository has been developed and is
copyrighted by the [StdLib](https://stdlib.com) Team at Polybit Inc. and is
MIT licensed. The specification itself is not intended to be owned by a
specific corporate entity, and has been developed in conjunction with other
developers and organizations.
