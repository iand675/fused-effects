{-# LANGUAGE ExistentialQuantification #-}
module Control.Effect.Catch
( Catch(..)
) where

import Control.Effect.Class

-- | 'Catch' effects can be used alongside 'Control.Effect.Throw.Throw' to provide recoverable exceptions.
data Catch e m k
  = forall b . Catch (m b) (e -> m b) (b -> m k)

instance HFunctor (Catch e)
instance Effect   (Catch e)
