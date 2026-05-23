---
name: memory-search
description: |
  搜索用户历史会话记忆。当用户提到"之前"、"上周"、"上次"、"记得我说过"、
  "回顾一下"等关键词，或需要参考过去的工作内容、决策、踩坑记录时激活。
---

## 用法
1. 使用 Shell 工具的 `grep -ri "关键词" ~/.kimi/memories/sessions/` 快速定位相关 session
2. 读取最相关的 1-3 个 session 摘要文件
3. 向用户提供历史信息的简要回顾

## 搜索策略
- 优先搜索最近 30 天的 session
- 如果用户提到具体时间（如"上周三"），用 `find` 按文件名日期过滤
- 摘要文件格式为 `<timestamp>_<session_hash>.md`
- 如果搜索无结果，告知用户"未找到相关历史记录"

## 注意事项
- 只读取 `~/.kimi/memories/sessions/` 下的文件
- 不要读取 `~/.kimi/sessions/` 下的原始会话数据（结构复杂）
- 提供历史信息时要注明来源 session 的日期
