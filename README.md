# Kimi 配置同步仓库

在多态远程服务器之间同步 Kimi Code CLI 的配置、Hooks 和 Skills。

## 同步范围

| 项目 | 仓库位置 | 软链目标 |
|------|----------|----------|
| 主配置 | `config.toml` | `~/.kimi/config.toml` |
| 钩子脚本 | `hooks/` | `~/.kimi/hooks/` |
| 技能 | `skills/` | `~/.kimi/skills/` |

**不同步**（机器本地运行时数据）：
- `sessions/`、`logs/`、`plans/`、`user-history/`
- `credentials/`、`kimi.json`、`mcp.json`

## 新机器部署

```bash
git clone https://github.com/go-bananas-wwj/kimi_settings.git ~/.kimi-config
cd ~/.kimi-config
bash install.sh

# 设置 ServerChan 通知密钥（如需微信通知）
export SERVERCHAN_SENDKEY="your-sendkey"

# 登录 Kimi 账号
kimi
/login
```

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

> **注意**：Skill 必须是 `skills/` 的**直接子目录**，不要嵌套分类文件夹。例如 `skills/my-skill/SKILL.md` ✅，不要 `skills/coding/my-skill/SKILL.md` ❌。

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

### 3. Flow Skill 执行
部分 Skill 支持流程化自动执行（需在 `SKILL.md` 中定义 `type: flow`）：

```
/flow:code-review
```

### 常用 Skill 清单

| Skill | 用途 |
|-------|------|
| `grill-me` | 压力测试你的计划和设计 |
| `brainstorming` | 头脑风暴和创意探索 |
| `tdd` | 测试驱动开发规范 |
| `typescript-magician` | TypeScript 类型体操 |
| `docx` | 创建和编辑 Word 文档 |
| `pptx` | 创建和编辑 PPT 演示文稿 |
| `pdf` | PDF 处理和表单填写 |
| `web-access` | 浏览器自动化操作 |
| `daily-news` | 每日资讯日报生成 |

查看全部 Skill：在 Kimi Shell 中输入 `/skills`（如果有此命令）或直接查看 `~/.kimi/skills/` 目录。

## 环境变量

| 变量 | 说明 |
|------|------|
| `SERVERCHAN_SENDKEY` | ServerChan 通知密钥，用于 Kimi 任务完成时发送微信通知 |

## 目录结构

```
kimi_settings/
├── config.toml          # Kimi 主配置（已脱敏）
├── hooks/               # 生命周期钩子脚本
│   ├── serverchan-notify.sh
│   └── serverchan-notify.py
├── skills/              # 35 个 Skill
│   ├── product-lens/
│   ├── grill-me/
│   ├── tdd/
│   └── ...
├── install.sh           # 一键安装脚本
├── .gitignore
└── README.md
```
