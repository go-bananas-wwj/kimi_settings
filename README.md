# Kimi 配置同步仓库

在多态远程服务器之间同步 Kimi Code CLI 的配置、Hooks、Skills、Prompts 和 Profiles。

## 同步范围

| 项目 | 仓库位置 | 软链目标 | 说明 |
|------|----------|----------|------|
| 主配置 | `config.toml` | `~/.kimi/config.toml` | 模型、Provider、Hooks 配置 |
| 钩子脚本 | `hooks/` | `~/.kimi/hooks/` | ServerChan 通知、Session 摘要 |
| 技能 | `skills/` | `~/.kimi/skills/` | 39 个 Skill（扁平结构） |
| 提示注入 | `prompts/` | `~/.kimi/prompts/` | UserPromptSubmit hook 注入内容 |
| 用户画像模板 | `profiles/` | — | 安装时复制到 `~/.kimi/memories/USER_PROFILE.md` |

**不同步**（机器本地运行时数据）：
- `sessions/`、`logs/`、`plans/`、`user-history/`
- `credentials/`、`kimi.json`、`mcp.json`

---

## 新机器部署

### 前置依赖

| 依赖 | 最低版本 | 检查命令 | 安装方式 |
|------|---------|---------|---------|
| Kimi CLI | ≥ 1.44.0 | `kimi --version` | `uv tool install kimi-cli` |
| Python 3 | ≥ 3.10 | `python3 --version` | 系统自带或 `apt install python3` |
| Node.js + npm | ≥ 18 | `node --version` | `apt install nodejs npm` |
| Git | — | `git --version` | `apt install git` |

> `uv` 安装参考：https://docs.astral.sh/uv/getting-started/installation/

### 一键配置

```bash
# 1. 克隆仓库
git clone https://github.com/go-bananas-wwj/kimi_settings.git ~/.kimi-config
cd ~/.kimi-config

# 2. 运行安装脚本（自动备份、建立软链、创建运行时目录）
bash install.sh

# 3. 配置 MCP（本地文件，不进 Git）
# 编辑 ~/.kimi/mcp.json，填入你的 API Key：
# {
#   "mcpServers": {
#     "context7": {
#       "url": "https://mcp.context7.com/mcp",
#       "transport": "http",
#       "headers": { "CONTEXT7_API_KEY": "your-key" }
#     }
#   }
# }

# 4. 设置 ServerChan 通知密钥（如需微信通知）
export SERVERCHAN_SENDKEY="your-sendkey"
# 建议加到 ~/.bashrc 永久生效

# 5. 登录 Kimi 账号
kimi
/login
```

### 部署验证

```bash
# 检查软链
ls -la ~/.kimi/config.toml ~/.kimi/skills ~/.kimi/hooks ~/.kimi/prompts

# 检查 Skill 数量（应输出 39）
ls ~/.kimi/skills | wc -l

# 检查用户画像
ls ~/.kimi/memories/USER_PROFILE.md

# 启动 Kimi，观察是否自动注入 skill 评估
kimi
```

---

## 同步更新

### 本机更新配置后推送到 GitHub

```bash
cd ~/.kimi-config
git add -A
git commit -m "feat: xxx"
git push
```

### 其他机器拉取更新

```bash
cd ~/.kimi-config && git pull
```

> 拉取后无需重新运行 `install.sh`，因为软链已经指向仓库目录，文件变更实时生效。

---

## 新增 Skill 并同步

```bash
# 创建 Skill（因为软链关系，实际写入仓库目录）
mkdir ~/.kimi/skills/my-skill
vim ~/.kimi/skills/my-skill/SKILL.md

# 提交并推送到 GitHub
cd ~/.kimi-config
git add skills/my-skill/
git commit -m "feat: add my-skill"
git push

# 其他机器拉取更新
cd ~/.kimi-config && git pull
```

> **注意**：Skill 必须是 `skills/` 的**直接子目录**，不要嵌套分类文件夹。
> 例如 `skills/my-skill/SKILL.md` ✅，`skills/coding/my-skill/SKILL.md` ❌。
> Kimi 的 skill 发现机制只扫描直接子目录。

---

## 快速使用 Skills

Kimi 启动时会自动读取所有 Skill。你可以通过以下方式使用：

### 1. 自动加载
普通对话时，Kimi 会根据上下文自动判断是否需要读取相关 Skill，无需手动操作。

### 2. 斜杠命令快速加载
输入 `/skill:<name>` 强制加载某个 Skill：

```
/skill:grill-me
/skill:pptx 帮我做一个关于人工智能的PPT
/skill:code-review
```

### 常用 Skill 清单

| Skill | 用途 |
|-------|------|
| `grill-me` | 压力测试你的计划和设计 |
| `brainstorming` | 头脑风暴和创意探索 |
| `reflect` | 自我反思与错误检查 |
| `critique` | 批判性审查自身输出 |
| `verification-before-completion` | 完成前强制验证 |
| `tdd` | 测试驱动开发规范 |
| `typescript-magician` | TypeScript 类型体操 |
| `docx` | 创建和编辑 Word 文档 |
| `pptx` | 创建和编辑 PPT 演示文稿 |
| `pdf` | PDF 处理和表单填写 |
| `xlsx` | Excel 表格处理 |
| `web-access` | 浏览器自动化操作 |
| `daily-news` | 每日资讯日报生成 |
| `geomaster` | 遥感/GIS/卫星影像分析 |
| `literature-review` | 文献综述与数据库检索 |
| `hypothesis-generation` | 科研假设生成 |
| `scientific-writing` | 学术论文写作 |
| `backtrader` | 量化策略回测框架 |
| `feature-engineering` | 量化特征工程 |
| `memory-search` | 搜索用户历史会话记忆 |

查看全部 Skill：`ls ~/.kimi/skills/`

---

## 环境变量

| 变量 | 说明 |
|------|------|
| `SERVERCHAN_SENDKEY` | ServerChan 通知密钥，用于 Kimi 任务完成时发送微信通知 |

### 可选环境变量

| 变量 | 说明 | 建议 |
|------|------|------|
| `KIMI_MODEL_THINKING_KEEP` | 设为 `all` 临时开启 Preserved Thinking | **不建议永久设置**，费用显著增加，仅在复杂调试会话中按需使用 |

---

## 维护脚本

```bash
# 清理 7 天前的旧 session（释放磁盘）
bash ~/.kimi-config/scripts/cleanup-sessions.sh 7

# 清理 30 天前的旧 session 摘要
bash ~/.kimi-config/scripts/cleanup-memories.sh 30
```

建议每周运行一次，或加入 crontab：
```bash
# 每周日凌晨清理
0 0 * * 0 bash ~/.kimi-config/scripts/cleanup-sessions.sh 7 >/dev/null 2>&1
0 0 * * 0 bash ~/.kimi-config/scripts/cleanup-memories.sh 30 >/dev/null 2>&1
```

---

## 常见问题

### Q: `kimi: command not found`
**A:** Kimi CLI 未安装。先安装 `uv`，然后 `uv tool install kimi-cli`。

### Q: Hook 启动报错 `command` 字段缺失
**A:** Kimi CLI 版本 < 1.44.0。升级：`uv tool upgrade kimi-cli`。

### Q: Skill 不识别或部分缺失
**A:** 检查是否有嵌套目录。Kimi 只扫描 `skills/` 的直接子目录。确保结构是 `skills/name/SKILL.md`，不要 `skills/category/name/SKILL.md`。

### Q: 通知 hook 不工作
**A:** 检查 `SERVERCHAN_SENDKEY` 环境变量是否设置。运行 `echo $SERVERCHAN_SENDKEY` 验证。

### Q: MCP 工具不生效
**A:** `~/.kimi/mcp.json` 是本地文件，不进 Git。新机器需要手动重新配置。

### Q: 如何更换用户画像？
**A:** 直接编辑 `~/.kimi/memories/USER_PROFILE.md`。这是本地文件，不会同步到其他机器。

---

## 目录结构

```
kimi_settings/
├── config.toml                    # Kimi 主配置（已脱敏）
├── install.sh                     # 一键安装脚本（含依赖检查）
├── README.md                      # 本文件
├── hooks/                         # 生命周期钩子脚本
│   ├── serverchan-notify.sh       # ServerChan 微信通知 + Session 摘要
│   └── serverchan-notify.py       # 辅助脚本
├── prompts/
│   └── skill-eval-reminder.md     # UserPromptSubmit 强制注入
├── profiles/                      # 用户画像模板
│   ├── default.md                 # 通用模板
│   └── researcher.md              # 遥感+量化研究者画像
├── skills/                        # 39 个 Skill（扁平结构）
│   ├── backtrader/
│   ├── brainstorming/
│   ├── geomaster/
│   ├── memory-search/
│   ├── web-access/
│   └── ...
└── scripts/                       # 维护脚本
    ├── cleanup-sessions.sh
    └── cleanup-memories.sh
```
