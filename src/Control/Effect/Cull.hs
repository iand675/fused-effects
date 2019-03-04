{-# LANGUAGE DeriveFunctor, ExistentialQuantification, FlexibleContexts, FlexibleInstances, GeneralizedNewtypeDeriving, LambdaCase, MultiParamTypeClasses, StandaloneDeriving, TypeOperators, UndecidableInstances #-}
module Control.Effect.Cull
( Cull(..)
, cull
, runCull
, CullC(..)
, runNonDetOnce
, OnceC(..)
) where

import Control.Applicative (Alternative(..))
import Control.Effect.Carrier
import Control.Effect.NonDet
import Control.Effect.Reader
import Control.Effect.Sum
import Control.Monad (MonadPlus(..))
import Control.Monad.Fail
import Control.Monad.IO.Class
import Prelude hiding (fail)

-- | 'Cull' effects are used with 'NonDet' to provide control over branching.
data Cull m k
  = forall a . Cull (m a) (a -> k)

deriving instance Functor (Cull m)

instance HFunctor Cull where
  hmap f (Cull m k) = Cull (f m) k
  {-# INLINE hmap #-}

instance Effect Cull where
  handle state handler (Cull m k) = Cull (handler (m <$ state)) (handler . fmap k)
  {-# INLINE handle #-}

-- | Cull nondeterminism in the argument, returning at most one result.
--
--   prop> run (runNonDet (runCull (cull (pure a <|> pure b)))) == [a]
--   prop> run (runNonDet (runCull (cull (pure a <|> pure b) <|> pure c))) == [a, c]
--   prop> run (runNonDet (runCull (cull (asum (map pure (repeat a)))))) == [a]
cull :: (Carrier sig m, Member Cull sig) => m a -> m a
cull m = send (Cull m pure)


-- | Run a 'Cull' effect. Branches outside of any 'cull' block will not be pruned.
--
--   prop> run (runNonDet (runCull (pure a <|> pure b))) == [a, b]
runCull :: Alternative m => CullC m a -> m a
runCull = runListAlt . runReader False . runCullC

newtype CullC m a = CullC { runCullC :: ReaderC Bool (ListC m) a }
  deriving (Applicative, Functor, Monad, MonadFail, MonadIO)

instance (Alternative m, Carrier sig m) => Alternative (CullC m) where
  empty = CullC empty
  l <|> r = CullC $ ReaderC $ \ cull -> ListC $ \ cons nil -> do
    runListC (runReader cull (runCullC l))
      (\ a as -> cons a (if cull then nil else as))
      (runListC (runReader cull (runCullC r)) cons nil)

instance (Alternative m, Carrier sig m) => MonadPlus (CullC m)

instance (Alternative m, Carrier sig m, Effect sig) => Carrier (Cull :+: NonDet :+: sig) (CullC m) where
  eff (L (Cull m k))     = CullC (local (const True) (runCullC m) >>= runCullC . k)
  eff (R (L Empty))      = empty
  eff (R (L (Choose k))) = k True <|> k False
  eff (R (R other))      = CullC (eff (R (R (handleCoercible other))))
  {-# INLINE eff #-}


-- | Run a 'NonDet' effect, returning the first successful result in an 'Alternative' functor.
--
--   Unlike 'runNonDet', this will terminate immediately upon finding a solution.
--
--   prop> run (runNonDetOnce (asum (map pure (repeat a)))) == [a]
--   prop> run (runNonDetOnce (asum (map pure (repeat a)))) == Just a
runNonDetOnce :: (Alternative f, Carrier sig m, Effect sig) => OnceC m a -> m (f a)
runNonDetOnce = runNonDet . runCull . cull . runOnceC

newtype OnceC m a = OnceC { runOnceC :: CullC (ListC m) a }
  deriving (Applicative, Functor, Monad, MonadFail, MonadIO)

deriving instance (Carrier sig m, Effect sig) => Alternative (OnceC m)
deriving instance (Carrier sig m, Effect sig) => MonadPlus (OnceC m)

instance (Carrier sig m, Effect sig) => Carrier (NonDet :+: sig) (OnceC m) where
  eff = OnceC . eff . R . R . handleCoercible


-- $setup
-- >>> :seti -XFlexibleContexts
-- >>> import Test.QuickCheck
-- >>> import Control.Effect.NonDet
-- >>> import Control.Effect.Void
-- >>> import Data.Foldable (asum)
