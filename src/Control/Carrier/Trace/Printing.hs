{-# LANGUAGE FlexibleInstances, GeneralizedNewtypeDeriving, MultiParamTypeClasses, TypeOperators, UndecidableInstances #-}

-- | A carrier for the 'Control.Effect.Trace' effect that prints all traced results to stderr.
module Control.Carrier.Trace.Printing
( -- * Trace effect
  module Control.Effect.Trace
  -- * Trace carrier
, runTrace
, TraceC(..)
  -- * Re-exports
, Carrier
, run
) where

import Control.Applicative (Alternative(..))
import Control.Carrier
import Control.Effect.Trace
import Control.Monad (MonadPlus(..))
import qualified Control.Monad.Fail as Fail
import Control.Monad.Fix
import Control.Monad.IO.Class
import Control.Monad.IO.Unlift
import Control.Monad.Trans.Class
import System.IO

-- | Run a 'Trace' effect, printing traces to 'stderr'.
runTrace :: TraceC m a -> m a
runTrace = runTraceC

-- | @since 1.0.0.0
newtype TraceC m a = TraceC { runTraceC :: m a }
  deriving (Alternative, Applicative, Functor, Monad, Fail.MonadFail, MonadFix, MonadIO, MonadPlus)

instance MonadTrans TraceC where
  lift = TraceC
  {-# INLINE lift #-}

instance MonadUnliftIO m => MonadUnliftIO (TraceC m) where
  askUnliftIO = TraceC $ withUnliftIO $ \u -> return (UnliftIO (unliftIO u . runTraceC))
  {-# INLINE askUnliftIO #-}
  withRunInIO inner = TraceC $ withRunInIO $ \run -> inner (run . runTraceC)
  {-# INLINE withRunInIO #-}

instance (MonadIO m, Carrier sig m) => Carrier (Trace :+: sig) (TraceC m) where
  eff (L (Trace s k)) = liftIO (hPutStrLn stderr s) *> k
  eff (R other)       = TraceC (eff (handleCoercible other))
  {-# INLINE eff #-}
