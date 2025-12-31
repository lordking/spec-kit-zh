# 文档

此文件夹包含使用[DocFX](https://dotnet.github.io/docfx/)构建的Spec Kit文档源文件。

## 本地构建

要在本地构建文档：

1. 安装DocFX：

   ```bash
   dotnet tool install -g docfx
   ```

2. 构建文档：

   ```bash
   cd i18n/zh/docs
   docfx docfx.json --serve
   ```

3. 在浏览器中打开 `http://localhost:8080` 查看文档。

## 结构

- `docfx.json` - DocFX配置文件
- `index.md` - 主文档主页
- `toc.yml` - 目录配置
- `installation.md` - 安装指南
- `quickstart.md` - 快速入门指南
- `_site/` - 生成的文档输出（被git忽略）

## 部署

当更改推送到`main`分支时，文档会自动构建并部署到GitHub Pages。工作流定义在`.github/workflows/docs-zh.yml`中。
