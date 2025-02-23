{-# LANGUAGE ConstraintKinds #-}
module Control.Carrier
( -- * Effect requests
  Has
, send
  -- * Re-exports
, module Control.Carrier.Class
, module Control.Carrier.Pure
, module Control.Effect.Class
, (:+:)(..)
) where

import Control.Carrier.Class
import Control.Carrier.Pure
import Control.Effect.Class
import Control.Effect.Sum

-- | @m@ is a carrier for @sig@ containing @eff@.
--
-- Note that if @eff@ is a sum, it will be decomposed into multiple 'Member' constraints. While this technically allows one to combine multiple unrelated effects into a single 'Has' constraint, doing so has two significant drawbacks:
--
-- 1. Due to [a problem with recursive type families](https://gitlab.haskell.org/ghc/ghc/issues/8095), this can lead to significantly slower compiles.
--
-- 2. It defeats @ghc@’s warnings for redundant constraints, and thus can lead to a proliferation of redundant constraints as code is changed.
type Has eff sig m = (Members eff sig, Carrier sig m)


-- | Construct a request for an effect to be interpreted by some handler later on.
send :: (Member eff sig, Carrier sig m) => eff m a -> m a
send = eff . inj
{-# INLINE send #-}
