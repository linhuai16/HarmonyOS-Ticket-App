# 麦麦（Maimai）HarmonyOS 购票客户端

麦麦是一个使用 **HarmonyOS / ArkTS / ArkUI** 开发的演出票务客户端，配套 `maimai-backend` Spring Boot 后端运行。

当前业务定位是 **第三方票源分销 / 代售平台的用户端**：客户端负责用户浏览、购票、订单、票夹、物流和退款体验；第三方票源差异统一由后端的Provider处理，处理后的数据交由后端管理。

> 一句话理解：**HarmonyOS 前端只认“麦麦业务模型”，不直接调用 Provider，也不向用户暴露 Provider 内部字段。**

---

## 概览

```text
首页 / 分类 / 搜索
        ↓
演出详情
        ↓
选择场次 + 一个票档
        ↓
选择数量 + 多个实名观演人
        ↓
提交订单
        ↓
支付
        ↓
电子票 / 动态码 / 纸质票物流
        ↓
票夹 / 订单 / 整单退款
```

核心规则：

- 一个订单 = **一个项目 + 一个场次 + 一个票档 + N 张同票档票**；
- 每张票绑定一个不同观演人；
- 支持电子票和纸质票；纸质票可按能力支持现场取票或快递；
- 用户退款按整单处理。

---

## 系统关系

```text
HarmonyOS 客户端
      │
      │ HTTP / JSON
      ▼
maimai-backend
      │
      │ Provider Adapter / Gateway
      ▼
第三方票源
LOCAL_MOCK/ 其他 Provider
```

前端不会直接请求第三方票源。新增 Provider 时，正常情况下只需要后端扩展 Adapter，HarmonyOS 页面继续使用统一的麦麦 API。

---

## 当前真实边界

### 已经不是本地 Mock 数据驱动

首页、分类、搜索、演出详情、票档、用户、观演人、地址、想看、订单、退款、票夹和物流等页面都通过 Repository 调用 Spring Boot API。

### 第三方票源联调使用 LOCAL_MOCK

后端提供完整票源模拟服务，可测试：

- 项目 / 场次 / 票档；
- 实时库存和价格变化；
- 下单、幂等和异常恢复；
- 出票、动态二维码；
- 纸质票物流；
- 退款；
- Provider 超时、响应丢失等异常。

### 仍属于测试实现

- 短信验证码不是生产短信服务；
- 支付为 Mock 支付；
- LOCAL_MOCK 是测试接口；
- 快递票只有一个详情页面，
- Provider为模拟接口
- 不支持用户自主选座

---

## 技术栈

| 项目 | 当前实现 |
|---|---|
| 语言 | ArkTS |
| UI | ArkUI |
| 模型 | Stage |
| SDK | HarmonyOS 6.1.0(23) |
| 架构 | MVVM + Repository |
| 网络 | `ApiClient` |
| 后端 | Spring Boot REST API |
| 主模块 | `entry` |
| 城市模块 | `module_city_select` |

主要调用关系：

```text
Page
 ↓
ViewModel
 ↓
Repository
 ↓
ApiClient
 ↓
Spring Boot
```

---

## 主要功能

### 首页 / 搜索 / 演出

- Banner、分类入口、推荐演出；
- 城市选择；
- 分类与搜索；
- 搜索历史；
- 演出详情、场馆、服务标签、观演须知；
- 想看 / 取消想看。
- 

### 购票

- 场次、票档和数量选择；
- 可售 / 售罄 / 未知库存展示；
- 实名观演人；
- 电子票 / 纸质票履约方式；
- 快递地址和运费；
- 提交订单幂等；
- 库存或价格变化时重新确认。

### 订单

- 订单列表和详情；
- 待支付倒计时；
- 取消订单；
- Mock 支付；

### 票夹 / 履约

- 电子票列表和详情；
- 静态票凭证；
- 动态二维码刷新；
- 出票中 / 可用 / 已使用 / 失效 / 异常；
- 纸质票配送和物流。

### 退款

- 退款确认；
- 退款规则和金额；
- 整单退款；

### 用户

- 登录；
- 我的；
- 用户资料；
- 观演人；
- 收货地址；
- 想看列表。

---

## 目录

主要目录：

```text
entry/src/main/ets/
├─ pages/          # ArkUI 页面
├─ viewmodel/      # 页面状态和交互逻辑
├─ repository/     # 后端 API 数据访问
├─ network/        # ApiClient / ApiConfig
├─ model/          # Entity / Enum / VO
├─ utils/          # 登录态、刷新通知、校验
└─ common/         # 通用组件和工具
```

---

```

---

## 运行

```text
DevEco Studio：使用支持 HarmonyOS 6.1.0 SDK 的版本
HarmonyOS SDK：6.1.0(23)
运行模块：entry
设备：phone / tablet
```

推荐启动顺序：

```text
MySQL
  ↓
maimai-backend :8080
  ↓
HarmonyOS entry
```

---

## 前后端职责边界

### 前端负责

- 页面和用户交互；
- 收集购票参数；
- 展示麦麦平台业务状态；
- 页面交互状态；
- 不保存 Provider 敏感集成信息。

### 后端负责

- 项目 / 场次 / 票档最终可售校验；
- 平台售价、Provider 价格和库存；
- Provider Adapter / Gateway；
- 下单与幂等；
- 第三方订单结果不确定恢复；
- 出票、动态凭证、物流；
- 整单退款；
- 回调、对账和日志；
- 对 Provider 内部字段进行用户侧脱敏。


---

## 配套后端

```text
maimai-backend
```
