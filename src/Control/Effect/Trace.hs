{-# LANGUAGE DeriveFunctor, DeriveGeneric, FlexibleContexts #-}

{- | An effect that provides a record of 'String' values ("traces") aggregate during the execution of a given computation.

Predefined carriers:

* "Control.Carrier.Trace.Printing", which logs to stderr in a 'Control.Monad.IO.Class.MonadIO' context.
* "Control.Carrier.Trace.Returning", which aggregates all traces in a @[String].
* "Control.Carrier.Trace.Ignoring", which discards all traced values.
-}

module Control.Effect.Trace
( -- * Trace effect
  Trace(..)
, trace
  -- * Re-exports
, Has
) where

import Control.Carrier
import GHC.Generics (Generic1)

-- | @since 0.1.0.0
data Trace m k = Trace
  { traceMessage :: String
  , traceCont    :: m k
  }
  deriving (Functor, Generic1)

instance HFunctor Trace
instance Effect   Trace

-- | Append a message to the trace log.
--
-- @since 0.1.0.0
trace :: Has Trace sig m => String -> m ()
trace message = send (Trace message (pure ()))
