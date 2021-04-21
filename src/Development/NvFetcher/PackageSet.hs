{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Development.NvFetcher.PackageSet
  ( PackageSet,
    package,
    pypiPackage,
    gitHubPackage,
    embedAction,
    purePackageSet,
    runPackageSet,
  )
where

import Control.Monad.Free
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import Development.NvFetcher.NixFetcher
import Development.NvFetcher.Types
import Development.Shake (Action)

-- | This is trivial XD
data PackageSetF f
  = NewPackage PackageName VersionSource (Version -> NixFetcher Fresh) f
  | forall a. EmbedAction (Action a) (a -> f)

instance Functor PackageSetF where
  fmap f (NewPackage name src fe g) = NewPackage name src fe $ f g
  fmap f (EmbedAction action g) = EmbedAction action $ f <$> g

type PackageSet = Free PackageSetF

package ::
  -- | package name
  PackageName ->
  -- | version source
  VersionSource ->
  -- | fetcher
  (Version -> NixFetcher Fresh) ->
  PackageSet ()
package name src fe = liftF $ NewPackage name src fe ()

pypiPackage ::
  -- | package name
  PackageName ->
  -- | pypi name
  Text ->
  PackageSet ()
pypiPackage name pypi = package name (Pypi pypi) $ pypiFetcher pypi

gitHubPackage ::
  -- | package name
  PackageName ->
  -- | owner and repo
  (Text, Text) ->
  PackageSet ()
gitHubPackage name (owner, repo) = package name (GitHub owner repo) $ gitHubFetcher (owner, repo)

embedAction :: Action a -> PackageSet a
embedAction action = liftF $ EmbedAction action id

purePackageSet :: [Package] -> PackageSet ()
purePackageSet = mapM_ (\Package {..} -> package pname pversion pfetcher)

runPackageSet :: PackageSet a -> Action (Set Package)
runPackageSet = \case
  Free (NewPackage name src fe g) -> (Package name src fe `Set.insert`) <$> runPackageSet g
  Free (EmbedAction action g) -> action >>= runPackageSet . g
  Pure _ -> pure Set.empty
