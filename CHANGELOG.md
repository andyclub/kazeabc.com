# CHANGELOG

## [v0.2.0] - 2026-05-06 22:37 JST

### 执行信息
- **执行时间**: 2026-05-06 22:37 JST
- **操作**: 新增 Agent / AI 项目安全经验总结文档
- **变更原文**: "应存入经验Github项目，版本号+0.1，注意将以上执行、测试、变更原文按+9时区时间戳，附加在changelog顶部，提交，推送"

### 新增内容
- **project-experience-library/Agent-AI安全经验/Agent-AI项目安全经验总结.md**: Agent / AI 项目安全经验总结
  - 核心原则：隐藏≠安全、前端不是安全边界、公网接口按敌对环境设计
  - 网络安全经验：localhost 监听、认证网关、不信任反向代理
  - 用户数据安全经验：user_id 隔离、不信客户端身份、写操作可回滚
  - AI/Agent 安全经验：Agent 默认不可信、禁止操作生产环境、高自治模式高风险
  - 状态机与任务安全：队列驱动、任务状态化、可观测性
  - 数据与 AI 成本控制：队列缓冲、二次确认
  - 工程安全经验：最小修改、日志优先
  - 组织级经验：权限最小化、人与 Agent 隔离、自动化需审计
  - 最终十项通用原则

### 测试
- 文件写入验证通过
- Git 仓库状态正常

### 变更记录
- feat: add Agent/AI security experience library

---

## [v0.1.0] - 2026-05-06 15:12 JST

### 执行信息
- **执行时间**: 2026-05-06 15:12 JST
- **操作**: 新增项目经验库目录 `project-experience-library/`，包含跨项目通用工程经验
- **变更原文**: "将该经验目录移入 git@github.com:andyclub/kazeabc.com.git 项目，并版本号+0.1"

### 新增内容
- **project-experience-library/**: 新增项目经验库
  - `README.md`: 索引入口
  - `通用工程规范/麦克风权限一次性授权机制.md`: 麦克风权限一次性授权机制说明文档

### 测试
- 文件结构验证通过
- Git 仓库状态正常

### 变更记录
- feat: add project-experience-library with microphone permission guide

---

## 历史版本
