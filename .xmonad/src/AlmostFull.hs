{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}

module AlmostFull ( AlmostFull(..) ) where
import XMonad
import qualified XMonad.StackSet as W
import Data.Maybe

data AlmostFull a = AlmostFull Rational Rational (Tall a) deriving (Read, Show)

numWindows (W.Stack _ l r) = 1 + length l + length r

instance LayoutClass AlmostFull a where
  pureLayout (AlmostFull ratio _ t) r@(Rectangle rx ry rw rh) s =
    case numWindows s of
      1 -> zip ws rs where
        ws = [W.focus s]
        rs = [Rectangle rx' ry rw' rh]
        rw' = ceiling . (ratio *) . fromIntegral $ rw
        rx' = rx + (ceiling $ (fromIntegral $ rw - rw') / (2.0 :: Double))
      _ -> pureLayout t r s

  handleMessage l m = withWindowSet $ \w ->
    return . pureAfMessage' l m . fromMaybe 1 $
    (W.stack . W.workspace . W.current $ w) >>= return . length . W.integrate

  description (AlmostFull _ratio _delta t) = "AlmostFull " ++ description t

pureAfMessage' :: AlmostFull a -> SomeMessage -> Int -> Maybe (AlmostFull a)
pureAfMessage' (AlmostFull ratio delta t) m winCount =
  case winCount of
    0 -> finalize (f $ fromMessage m) (Just t)
    1 -> finalize (f $ fromMessage m) (Just t)
    _ -> finalize (Just ratio) (pureMessage t m)
  where
    finalize :: Maybe Rational -> Maybe (Tall a) -> Maybe (AlmostFull a)
    finalize (Just ratio_) (Just tall_) =
      Just $ AlmostFull ratio_ delta tall_
    finalize _ _ = Nothing

    f (Just Shrink) = Just (max 0 $ ratio-delta)
    f (Just Expand) = Just (min 1 $ ratio+delta)
    f _             = Nothing
