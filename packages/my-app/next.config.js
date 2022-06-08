/** @type {import('next').NextConfig} */

const withTM = require("next-transpile-modules")(["shared"]); // トランスパイルモジュールを渡します。

const nextConfig = withTM({
  reactStrictMode: true,
});

module.exports = nextConfig;
