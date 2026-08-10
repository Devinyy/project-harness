# 本项目类型检查命令（verify-before-stop hook 读取首行非注释）
# 自动探测自 package.json，按真实情况修正（如 monorepo filter）
pnpm exec vue-tsc --noEmit
