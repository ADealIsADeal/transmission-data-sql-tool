# 传输中台数据自助

面向传输中台数据分析与取数场景的纯静态网页工具。项目将数据血缘、字段说明、加工逻辑、指标配置和 SQL 生成能力集中在一个页面中，便于查询分析和自助取数。

## 功能

- 数据表与字段血缘浏览
- 字段标准化规则和加工逻辑查看
- 指标、维度、时间范围与筛选条件配置
- 根据配置生成 SQL，并支持复制
- 常用工具页面嵌入
- 适配桌面端和移动端布局

## 项目结构

| 文件 | 说明 |
| --- | --- |
| `index.html` | 四页导航首页 |
| `自助取数.html`、`指标中心.html`、`数据血缘.html`、`常用工具.html` | 独立页面入口，加载 app.html |
| `app.html` | 共享应用页面 |
| `传输库血缘与自助取数.html` | 与 app.html 同步的兼容入口 |
| `assets/metric-center/` | 指标中心、字段血缘模块与 SQL 提取目录 |
| `dev_toolkit.html` | 内嵌的常用工具页面 |
| `site.webmanifest` | PWA 配置 |
| `favicon*`、`apple-touch-icon.png`、`safari-pinned-tab.svg` | 网站图标资源 |

## 本地运行

这是一个无需构建的静态 HTML 项目。可以直接打开入口文件，也可以在项目目录启动任意静态文件服务器：

```bash
python3 -m http.server 8000
```

然后访问 <http://localhost:8000/>，或直接进入 <http://localhost:8000/指标中心.html>。

## 部署

项目可部署到 GitHub Pages、CloudBase、Nginx 或其他静态托管服务。部署时请将整个项目目录作为网站根目录，并使用 `index.html` 作为导航首页。

## 注意事项

- 页面内嵌线上加工 SQL 摘录与字段来源目录；不包含业务数据或数据库连接信息。
- 页面生成的是查询模板，实际执行前请根据目标数据仓库的 SQL 方言和权限进行校验。
- 保留四页导航及两个共享应用入口；更新应用时应同步 `app.html` 和 `传输库血缘与自助取数.html`。

## License

本项目暂未声明开源许可证。未经许可，请勿将其中的业务规则、字段信息或页面内容用于商业用途。

## 指标中心与字段血缘更新

唯一线上 SQL 来源为 `SQL/任务结束上报/`，保留原始文件名、头部说明和 DDL 注释。分片文件名为 `dws_xlyun_transfer_download_seqid_d_incs.sql`，实际目标表以文件中的 INSERT 为准（`dws_xlyun_transfer_download_seqid_d_inc`）。

更新此目录 SQL 后运行：

```bash
python3 assets/metric-center/build_catalog.py
```

命令重新提取 6 个任务的字段表达式、源文件行号与 SHA-256，更新 catalog.json、兼容 SQL 下载文件及两个应用入口。页面中表血缘、字段血缘和指标详情的线上 SQL 均展示此目录的完整原文，下载链接直接指向原文件。GitHub 部署也会先运行此命令，因此更新目录中的 SQL 后部署会自动刷新原文及字段目录。

当前覆盖 20 项指标、分片 78 个和子任务 77 个输出字段。子任务零速按 `max(seq_zero_speed) = '1' and sum(recv_bytes) = 0`；分片 DWS 新增后台/预部署任务过滤、六个大小/流量字段分别小于 10 TiB、版本点号检查及 PC 产品范围限制，采集信息来自 `dim_xlyun_transfer_mp_gcid_info_d_inc`。

提取器的 FROM/JOIN 绑定针对当前六个任务；SQL 结构或业务规则变化时，需复核 build_catalog.py 中的 bindings、center.js 指标口径与页面表说明。自动构建更新原文和表达式，不自动推断自然语言口径。字段血缘展示值的直接依赖，过滤和关联条件请查看完整 SQL；DDL 注释不代表线上数据库校验。

## 数据空间与心跳血缘

页面顶部可切换「任务结束上报」与「心跳上报」。两空间使用独立目录、字段关系、表选择、搜索及页签状态；切换后保留各自当前浏览位置，浏览器记住所选空间。心跳空间只开放数据血缘及常用工具，不配置指标或取数模板。

- `SQL/任务结束上报/`：任务结束链路的 6 份原始 SQL。
- `SQL/心跳上报/`：上行、下行共 8 份原始 SQL（ODS → DWD → DWS → ADS）。
- `assets/heartbeat/`：独立心跳目录生成器、前端及字段依赖校验。

运行 `python3 assets/metric-center/build_catalog.py` 会分别构建两个目录并嵌入页面，部署流程也执行该命令。心跳字段覆盖静态分区、嵌套 SELECT、UNPIVOT 六类流量展开和 DCDN 扣减 PCDN；SQL 弹窗与下载均使用对应空间的完整原文件。未提供加工 SQL 的 PRE 仅显示为上游来源，不推测其加工逻辑。

心跳提取器针对当前单来源嵌套 SELECT 结构校验绑定；新增 JOIN、CTE 或其他结构时会停止构建，需先更新解析逻辑。校验命令：`python3 assets/heartbeat/test_catalog.py`。
