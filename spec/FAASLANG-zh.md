FaaSlang
--------

# FaaSlang

![FaaSlang Logo](https://raw.githubusercontent.com/graphql-faas/faaslang/gh-pages/images/faaslang-logo-small.png)

## 函数即服务的语言

以下是最新的FaaSlang规范的工作草案，版本**0.3.x**，日期为**2018年2月12日**。

FaaSlang是一个简单的**开放规范**,用于定义关于FaaS（“无服务器”）函数，网关和客户端接口
（来自任何语言/SDK的请求）的语义和实现细节. 它通过约定文档和接口(**如:类型安全机制**)
来降低FaaS微服务的结构复杂性. 同样地, GraphQL为接口和嵌套关系(graph)数据提供了意见和规范.
FaaSlang为FaaS资源做了同样的事情.

如果你使用FaaSlang-compliant的部署和API网关 (如:https://stdlib.com).
无服务函数相比于传统网关有如下优点:

- 标准调用约定(HTTP)
- 类型安全
- 强制文档(Enforced Documentation)
- 后台执行(立即响应, worker形式运行)

而这仅仅是个开始。您正在寻找的所有好东西，如速率限制，身份验证等，都不是FaaSlang规范的
一部分，但它们可以轻松的被添加到这个存储库所提供的示例中。

# 目录

1. [介绍](#introduction)
1. [为何选择FaaSlang？](#why-faaslang)
1. [规范](#specification)
   1. [FaaSlang资源定义](#faaslang-resource-definition)
   1. [上下文定义](#context-definition)
   1. [参数](#parameters)
      1. [约束](#constraints)
      1. [类型](#types)
      1. [类型转换](#type-conversion)
      1. [为空性(nullability)](#nullability)
   1. [FaaSlang资源请求](#faaslang-resource-requests)
      1. [上下文](#context)
      1. [错误](#errors)
         1. [客户端错误](#clienterror)
         1. [参数错误](#parametererror)
            1. [细节: 必填](#details-required)
            1. [细节: 无效](#details-invalid)
         1. [Fatal错误](#fatalerror)
         1. [运行时错误](#runtimeerror)
         1. [值错误](#valueerror)
1. [FaaSlang服务和网关: 实现](#faaslang-server-and-gateway-implementation)
1. [致谢](#acknowledgements)

# FaaSlang是什么?

简而言之, FaaSlang通过下面的方式定义无服务函数的部署和执行(API)网关的语义和规则:

```javascript
// hello_world.js

/**
* My hello world function!
*/
module.exports = function (name = 'world', callback) {

  callback(null, `hello ${name}`);

};
```

它可以通过HTTP调用,无限扩展web接口(使用"无服务"提供器(providers))
GET方式:

```
https://myhost.com/username/servicename/hello_world?name=joe
```

POST方式:

```json
{
  "name": "joe"
}
```

获取的结果:

```json
"hello joe"
```

当类型不匹配时(如`{"name":10}`):

```json
{
  "error": {
    "type":"ParameterError"
    ...
  }
}
```

# 为什么选择FaaSlang?

"无服务"的范围正在快速增长,同时,它所需的工具链也是如此.但是每一个基础服务提供商都有
自己FaaS标准,以至于我们依赖每个开发者来选择最佳的部署框架.

FaaSlang采用不同的方法,它提供API网关规范(和强大的,非供应商特定的Node.js实现),作为
"锁定"你和你的团队成员部署和执行"无服务"函数的方式.

如:AWS Lambda函数示例 **(A)**;

```javascript
exports.handler = (event, context, callback) => {
  let myVar = event.myVar;
  let requiredVar = event.requiredVar;
  myVar = myVar === undefined ? 1 : myVar;
  callback(null, 'Hello from Lambda!');
};
```

或Microsoft Azure函数示例 **(B)**;

```javascript
module.exports = function (context, req) {
  let myVar = req.query.myVar || req.body && req.body.myVar;
  let requiredVar = req.query.requiredVar || req.body && req.body.requiredVar;
  myVar = myVar === undefined ? 1 : myVar;
  context.res = {body: 'Hello from Microsoft Azure!'};
  context.done();
}
```

FaaSlang定义Node.js函数脚本:

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

为了类型安全(无法通过默认推断出类型的情形)**注释往往被用于语义定义的一部分**,
它期待一个指定的参数定义,也可以通过`上下文`推导得出(参数重载等).

通用的FaaS工作流如下:

![通用的FaaS工作流](https://raw.githubusercontent.com/graphql-faas/faaslang/gh-pages/images/current-faas-workflow.jpg)

这是启用FaaSlang的工作流程的样子。

![FaaSlang工作流](https://raw.githubusercontent.com/graphql-faas/faaslang/gh-pages/images/faaslang-workflow.jpg)

FaaSlang是成千上万的FaaS部署的结果,通过无数开发者,它分布在众多云服务提供商之间,需要
通过这些函数实现我们组织和通讯的标准化.

# 规范

## FaaSlang资源定义

一个FaaSlang定义是一个`definition.json`文件,他应该遵守下面的格式.

给定这样的函数 (文件名 `my_function.js`):

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

你应该提供如下的函数定义:

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

这个定义是*可扩展的*,即你可以添加其他字段,但**必须**遵守这个模式.

定义必须实现下面的字段;

| 字段 | 定义 |
| ----- | ---------- |
| name | 用户友好的函数名称(用于执行函数),必须匹配 `/[A-Z][A-Z0-9_]*/i` |
| format | 要求包含`language`字段的对象和其他一些细节 |
| description | 简短的函数目的介绍,可为空 (`""`) |
| bg | 包含“mode”和“value”参数的对象，指定在后台执行时函数响应的行为 |
| charge | 一个0-100的整数,定义函数运行的成本,以向认证用户收费 |
| params | 是一个`NamedParameter`数组, 便是函数参数
| returns | 是一个没有默认值的参数,表示函数返回值 |

## 上下文(context)定义

如果函数没有访问上下文(context),它应该始终为null. 如果它是一个对象,则表示函数*确实*访问了
上下文(context)(即`remoteAddress`http headers等 - 参考 [Context](#context)).

上下文对象**不要求为空**,它可以包含特点供应商的详细信息;如 `"context": {"user": ["id", "email"]}`
可以表明执行上下文指定访问的,已认证用户的id和邮箱地址.

## 参数

参数具有如下格式;

| 字段 | 必填 | 定义 |
| ----- | -------- | ---------- |
| name | 仅限NamedParameter | 参数的名称必须匹配 `/[A-Z][A-Z0-9_]*/i` |
| type | 是 | 表示有效FaaSlang类型的字符串 |
| description | 是 | 参数的简短描述，可以是空字符串(`""`) |
| defaultValue | 否 | 必须匹配指定类型, **否则提供此参数是必需的** |

### 约束

**第一个参数不能是"Object"类型**.这是为了确保所有语言实现中的泛型调用（即支持参数重载）
的请求一致性。

### 类型

由于FaaSlang应用于多语言环境,函数定义必须有强类型签名.并非所有类型都保证在每种语言中
都以相同的方式使用，我们将继续定义每种语言应如何与FaaSlang类型接口的规范。目前，类型
是JSON值的有限超集。

| 类型 | 定义 | 示例输入值 (JSON) |
| ---- | ---------- | -------------- |
| boolean | True 或 False | `true` 或 `false` |
| string | 基本文本或字符串 | `"hello"`, `"GOODBYE!"` |
| number | 任何双精度浮点值 [Floating Point](https://en.wikipedia.org/wiki/IEEE_floating_point) value | `2e+100`, `1.02`, `-5` |
| float | `number`的别名 | `2e+100`, `1.02`, `-5` |
| integer | `number`的子集, integers 取值区间为 `-2^53 + 1` 到 `+2^53 - 1` (包含) | `0`, `-5`, `2000` |
| object | 任何JSON可序列化的对象 | `{}`, `{"a":true}`, `{"hello":["world"]}` |
| object.http | HTTP响应的对象. 接受 `headers`, `body` 和 `statusCode` keys | `{"body": "Hello World"}`, `{"statusCode": 404, "body": "not found"}`, `{"headers": {"Content-Type": "image/png"}, "body": new Buffer(...)}` |
| array | 任何JSON可序列化数组 | `[]`, `[1, 2, 3]`, `[{"a":true}, null, 5]` |
| buffer | 表示文件的原始二进制八位字节（byte）数据 | `{"_bytes": [8, 255]}` or `{"_base64": "d2h5IGRpZCB5b3UgcGFyc2UgdGhpcz8/"}` |
| any | 上面提到的任何值 | `5`, `"hello"`, `[]` |

### 类型转换

`object`(**匹配这个脚本的单键值对`{"_bytes": []}`或`{"_base64": ""}`**)类型将自动转换
为`buffer`类型.

否则，提供给函数的参数应与其定义的类型匹配。请求参数通过HTTP请求或POST数据格式
为`application/x-www-form-urlencoded`将自动从字符串转换为定义的类型(详
见下面的[FaaSlang资源请求](#faaslang-resource-requests)):

| 类型 | 转换规则 |
| ---- | --------------- |
| boolean | `"t"` 和 `"true"` 转为 `true`, `"f"` 和 `"false"` 转为 `false`, 否则 **不转换** |
| string | 没有转换 |
| number | 取决于浮点值, 如果为NaN **不转换**, 否则转换 |
| float | 取决于浮点值, 如果为NaN **不转换**, 否则转换 |
| integer | 取决于浮点值, 如果为NaN **不转换**, 如果不在范围内，会造成类型检查失败 |
| object | 解析为JSON, 如果为invalid **不转换**, (array, buffer)类型会造成类型检查失败 |
| object.http | 解析为JSON, 如果为invalid **不转换**, (array, buffer)类型会造成类型检查失败 |
| array | 解析为JSON, 如果为invalid **不转换**, (object, buffer)类型会造成类型检查失败 |
| buffer | 解析为JSON, 如果为invalid **不转换**, (object, array)类型会造成类型检查失败 |
| any | 没有转换 |

### 为空性

所有类型都可以为空，但只能通过在`NamedParameter`定义中设置`"defaultValue": null`
来 **指定可空性**。也就是说，如果提供了默认值，则该类型不可以为空。

### 设置HTTP头

FaaSlang规范并非仅用于HTTP，但如果通过HTTP使用提供的回调方法，**则传递给回调的第三个参数应该是表示HTTP Header键值对的Object。**

例如，要返回类型为image/png... 的图片

```javascript
module.exports = (imageName, callback) => {

  // 获取图片,返回一个buffer
  let png = imageName === 'cat' ?
    fs.readFileSync(`/images/kitty.png`) :
    fs.readFileSync(`/images/no-image.png`);

  // HTTP请求是image/png格式, 默认是buffer,可设置为application/octet-stream
  return callback(null, png, {'Content-Type': 'image/png'});

};
```

**只有在回调结束函数时**才能使用第三个参数，即不能与异步函数一起使用。这可用于通过HTTP，
设置缓存详细信息（E-Tag标头）等提供任何类型的内容。

## FaaSlang资源请求

FaaSlang-compliant 请求 *必须* 完成以下步骤;

1. 确保 **资源定义** 在存储或加入时有效且符合要求
1. 执行HTTP握手并进行请求信息初始化
1. 接收`Array`, `Object` 或进行URL编码的字符串变量
1. 如果存在HTTP和查询参数，则将查询参数用作URL编码变量
1. 如果存在HTTP POST和查询参数,会拒绝指定POST请求体和`ClientError`
1. 如果通过HTTP POST,请求结果 **必须** 包含`Content-Type`标头或立即返回`ClientError`
1. 如果通过HTTP POST,`Content-Type` **必须** 是`application/json`格式的`Array`或`Object`,或者是`application/x-www-form-urlencoded`格式的字符串或立即返回`ClientError`
1. 如果值(通过POST请求体或查询参数获取)是 `application/x-www-form-urlencoded`格式,将根据[类型转换](#type-conversion)和函数定义信息确定创建`Object`的类型
1. 如果是`Array`: 会按顺序检查已定义的`params`类型一致性的
1. 如果是`Object`: 会根据`params`名称检查类型一致性
1. 如果发现存在不一致的地方,停止执行并返回`ParameterError`
1. 如果参数未设置默认值或未提供参数,将返回`ParameterError`
1. 如果函数执行时解析失败或无效,则返回`FatalError`
1. 如果函数达到指定超时(执行时间限制),返回`FatalError`
1. 如果函数返回错误(使用回调)或者抛出未捕获异常,返回`RuntimeError`
1. 如果函数返回不一致的响应（与returns类型不匹配），则返回`ValueError`
1. 如果未遇到任何错误，返回值给客户端
1. 如果通过HTTP并且`content-type`没有过载(即:指定供应商以指定开发人员的机制),将以`application/octet-stream`格式返回`buffer`数据,以`application/json`格式返回其他数据.

### 上下文

每个使用FaaSlang的函数都可以指定一个*可选的*`context`参数,以获取指定供应商关于函数执行的上下文
信息 - 比如,HTTP头信息.FaaSlang定义必须指定它们是否使用context对象。Context对象是可扩展的，
但 **必须**包含以下字段;

| 字段 | 定义 |
| ----- | ---------- |
| params | 包含参数键值对映射的`object`类型 |
| http | 如果未通过HTTP访问,则返回`null`,其他返回`object` |
| http.headers | 如果通过HTTP访问,则`object`包含请求头的值 |

### 错误

FaaSlang-compliant服务返回的错误必须遵循以下JSON格式:

```json
{
  "error": {
    "type": "ClientError",
    "message": "You know nothing, Jon Snow",
    "details": {}
  }
}
```

`details`是一个可选对象，可以提供其他参数详细信息。
错误类型如下:

- `ClientError`
- `ParameterError`
- `FatalError`
- `RuntimeError`
- `ValueError`

#### ClientError

`ClientError`当客户端数据错误或者格式错误是返回,包括缺少认证或函数缺少(未找到).如果使用HTTP,返回的状态码 **必须** 在`4xx`范围内.

#### ParameterError

`ParameterError`当参数未通过类型安全检查时返回,如果使用HTTP,**必须**返回`400`状态码.
格式:

```json
{
  "error": {
    "type": "ParameterError",
    "message": "ParameterError",
    "details": {...}
  }
}
```

`"details"`是参数名称和其(类型检查)校验错误的映射关系对象.目前,该规范为参数定义了
ParameterError的两个分类; *必填*和*无效*.它的格式如下:

##### Details: 必填

```json
{
  "param_name": {
    "message": "((descriptive message stating parameter is required))",
    "required": true
  }
}
```

##### Details: 无效

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

`FatalError`是函数管理不善的结果 - 如无法加载,执行,超时.如果使用HTTP,这时 **必须**返回`500`状态码.

#### RuntimeError

`RuntimeError`是代码运行时发生未捕获异常的结果,包括自定义抛出的异常(或通过回调发送给客户端).如果使用HTTP,这时 **必须** 返回`403`状态码.

#### ValueError

`ValueError`是函数基于FaaSlang类型安全机制返回一个未定义的值的结果.如果使用HTTP,这时 **必须**返回`502`状态码.

`ValueError`看起来像一个*无效的* ParameterError，其中`details`对象只有一个名为`"returns"`的键. 如果函数开发者的实现有误,会造成这个问题.

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

# FaaSlang服务器和网关: 实现

此软件包提供完全兼容的FaaSlang网关（仅使用本地功能资源），只需克隆它并运行`npm test`
或查看该`/tests`文件夹以获取更多信息。

目前FaaSlang规范被FaaS提供商[StdLib](https://stdlib.com)用于生产环境,并且可以与
[StdLib CLI Package](https://github.com/stdlib/lib)一起在本地使用，该程序包依赖于
此存储库作为依赖项。

# 致谢

此存储库中包含的软件已由Polybit公司的[StdLib](https://stdlib.com)团队开发并受版权
保护，并获得MIT许可。规范本身并非特定公司实体拥有，而是与其他开发人员和组织共同开发。
