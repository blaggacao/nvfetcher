{-# LANGUAGE OverloadedStrings #-}

module Main where

import NvFetcher

main :: IO ()
main = runNvFetcher packageSet

packageSet :: PackageSet ()
packageSet = do
  define $ package "fd" `fromGitHub` ("sharkdp", "fd") `extractSource` ["Cargo.lock"]

  define $ package "gcc-10" `fromGitHubTag` ("gcc-mirror", "gcc", includeRegex ?~ "releases/gcc-10.*")

  define $ package "feeluown-core" `fromPypi` "feeluown"

  define $ package "qliveplayer" `fromGitHub'` ("IsoaSFlus", "QLivePlayer", fetchSubmodules .~ True)

  define $
    package "apple-emoji"
      `sourceManual` "0.0.0.20200413"
      `fetchUrl` const
        "https://github.com/samuelngs/apple-emoji-linux/releases/download/latest/AppleColorEmoji.ttf"

  define $
    package "nvfetcher-git"
      `sourceGit` "https://github.com/berberman/nvfetcher"
      `fetchGitHub` ("berberman", "nvfetcher")

  define $
    package "vim"
      `sourceWebpage` ("http://ftp.vim.org/pub/vim/patches/7.3/", "7\\.3\\.\\d+", id)
      `fetchGitHub` ("vim", "vim")
      `tweakVersion` (\v -> v & fromPattern ?~ "(.+)" & toPattern ?~ "v\\1")

  define $
    package "rust-git-dependency-example"
      `sourceManual` "8a5f37a8f80a3b05290707febf57e88661cee442"
      `fetchGit` "https://gist.github.com/NickCao/6c4dbc4e15db5da107de6cdb89578375"
      `hasCargoLock` "Cargo.lock"
