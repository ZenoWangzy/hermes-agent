# gbrain 知识库（会话摘录）

> 最近更新：2026-04-17 11:27 (+08:00)
> 说明：记录你发来的链接与可复用洞察，后续在相关话题中主动提醒使用。

## 条目 1：Andrej Karpathy Skills（源头仓库）
- 关键词：`andrej-karpathy-skills`
- 源头仓库：`forrestchang/andrej-karpathy-skills`
- 定位：把 Karpathy 对 LLM 编码坑点的观察，整理为可执行规范（CLAUDE.md / skills / plugin）。
- 可复用点：
  - Think Before Coding
  - Simplicity First
  - Surgical Changes
  - Goal-Driven Execution

## 条目 2：Harness 文档站
- 链接：https://taowang1993.github.io/harness/
- 定位：对比 Codex CLI / Claude Code / OpenCode / Pi / Hermes 的系统化分析手册。
- 高价值章节：
  - Agent Matrix（总览对比）
  - Tool System（工具哲学与扩展机制）
  - Prompt Engineering（提示词架构差异）
  - Multi-Agent Architecture（多代理隔离与协作）
  - Version Pinning（版本与来源边界）

## 条目 3：X 文章（dbuniatyan）
- 链接：https://x.com/dbuniatyan/status/2043711223204819295?s=46
- 状态：已记录，待你后续需要时再做重点拆解。

## 条目 4：X 文章（intuitiveml）
- 链接：https://x.com/intuitiveml/status/2043545596699750791?s=46
- 主题：AI-first / Harness Engineering
- 反常识洞察：
  - AI-first 不是“加个 AI 工具”，而是重构全链路流程。
  - 瓶颈会迁移到 PM/QA/发布/营销，不会自动消失。
  - 先建验证与回滚系统，再追求生成速度。
  - 工程师价值从“写代码快”转向“定义标准与风险判断”。

## 条目 5：X 长文（akshay_pachaar）Agent Memory 演进与 Cognee
- 链接：https://x.com/akshay_pachaar/status/2043745099792953508?s=46
- 主题：为什么“长上下文 ≠ 记忆”，以及 agent memory 从列表/markdown 到 vector+graph 的演进。
- 核心点：
  - 仅靠上下文窗口会触发 lost-in-the-middle，且没有持久化与优先级机制。
  - 纯 markdown/关键词检索在规模上会失效（同义词、多跳关系、跨事实连接）。
  - 纯向量检索解决语义相似，但对多跳关系推理仍有盲区。
  - 作者主张三层结合：关系型（溯源权限）+ 向量（语义）+ 图（关系）。
- 可复用洞察：
  - 给 agent memory 设计时优先按“查询形态”选架构：相似检索 vs 多跳关系问答。
  - 先定义 memory lifecycle：写入→抽取→索引→检索→回写→衰减/强化。
  - 将“会话记忆”和“长期记忆”分层，避免所有内容都堆进 prompt。
  - 对外部项目宣传文要做版本核验（例如 API 可能已从 add/cognify/memify/search 演进为 remember/recall/forget/improve）。
- 状态：已拆解（含交叉核验）

## 用户偏好（长期）
- 你发来的链接与资料，默认进入 gbrain 知识库。
- 在相关话题出现时，主动提醒你复用这些条目。
