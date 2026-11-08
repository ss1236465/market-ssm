# market-ssm — 超市进销存管理系统

基于 Java、Spring MVC、MyBatis、JSP 和 Maven 的超市进销存管理项目。

包含管理员与员工登录，以及商品、库存、进货、销售、退货、供应商和客户管理等功能。

## 项目位置

完整 Maven 项目位于 `market-master/market`，数据库初始化脚本为该目录中的 `market.sql`。

## 运行环境

- JDK 8
- Maven
- Tomcat 9
- MySQL 8.0

初次在其他电脑运行时，需要创建 `market` 数据库、导入 `market.sql`，按本机环境配置 `src/main/resources/db.properties`，然后执行 `mvn package`，将生成的 `target/chaoshi.war` 部署到 Tomcat。

已配置好运行环境的原电脑可以双击项目目录中的 `启动项目.cmd`；停止服务使用 `停止项目.cmd`。详细说明见 `market-master/market/本地运行说明.md`。

本机运行地址：`http://127.0.0.1:8080/chaoshi/`。

## 示例账号

| 角色 | 账号 | 密码 |
| --- | --- | --- |
| 管理员 | 15203111 | 1234 |
| 普通员工 | 15203122 | 123456 |

这些账号仅用于本地演示。SQL 中的身份证号和手机号已替换为测试数据。

## 发布内容

仓库包含源码、静态资源、示例 SQL 与本地启动脚本。运行工具、数据库数据目录、构建结果及本机密码备份保存在被 Git 忽略的 `.local` 或 `target` 目录中。

源配置中的数据库密码留空，使用时在本机配置；请勿将真实密码提交到仓库。

原项目说明保留在 `market-master/README.md`。本次配置补充了 Java 8/UTF-8 编译设置、MySQL 8 驱动，并移除了缺失的启动 Servlet 配置。
