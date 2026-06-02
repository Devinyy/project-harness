# AGENTS.md — src/api/（模版 · uni-app）
API 调用层，一领域一文件。详见 docs/specs/07_API_CONTRACTS.md。
- 经 @/utils/request，禁裸 uni.request/luch-request
- 返回类型显式（DTO 在 src/types）；命名 getXxx/createXxx/updateXxx/deleteXxx
