# 必要なときだけ依存関係をインストールする
FROM node:16-alpine AS deps
# なぜ libc6-compat が必要なのかを理解するために https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine を確認してください。
# 不足する共有ライブラリをイメージに追加するには をイメージに追加するには、Dockerfile にlibc6-compat パッケージをDockerfileに追加することが推奨されます
RUN apk add --no-cache libc6-compat

WORKDIR /app
COPY package.json yarn.lock ./
COPY packages/my-app/package.json ./packages/my-app
COPY packages/shared/package.json ./packages/shared

RUN yarn install --frozen-lockfile

# 必要なときだけソースコードをリビルドする
FROM node:16-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules

# TODO: ビルドに必要なファイルだけにコピーを絞る
COPY . .

RUN yarn workspace my-app build


# プロダクション・イメージを作成し、すべてのファイルをコピーして、次に実行します。
FROM node:16-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# デフォルトの設定を使用しない場合のみ、next.config.jsをコピーする必要があります。
# COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# 出力トレースを自動的に活用して画像サイズを削減
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
