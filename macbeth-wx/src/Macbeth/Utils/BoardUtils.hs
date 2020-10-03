module Macbeth.Utils.BoardUtils (
  drawArrow,
  squareToRect',
  squareToPoint,
  toPos',
  toPosLabelRow,
  toPosLabelCol
) where

import           Graphics.UI.WX hiding (size, color)
import           Macbeth.Fics.Api.Api

rowToInt :: Macbeth.Fics.Api.Api.PColor -> Row -> Int
rowToInt White = abs . (7-) . fromEnum
rowToInt Black = fromEnum


colToInt :: Macbeth.Fics.Api.Api.PColor -> Column -> Int
colToInt White = fromEnum
colToInt Black = abs . (7-) . fromEnum


toPos' :: Int -> Square -> PColor -> Point
toPos' size' (Square c r) color' = point (colToInt color' c * size') (rowToInt color' r * size')

toPosLabelRow :: Int -> Square -> PColor -> Point
toPosLabelRow size (Square col row) color = point x y
  where x = (colToInt color col * size) + size - 8
        y = (rowToInt color row * size)

toPosLabelCol :: Int -> Square -> PColor -> Point
toPosLabelCol size (Square col row) color = point x y
  where x = (colToInt color col * size) + 2
        y = (rowToInt color row * size) + size - 8 - 5

squareToPoint :: Int -> Square -> PColor -> Point
squareToPoint size sq color = rectCentralPoint $ squareToRect' size sq color

squareToRect' :: Int -> Square -> PColor -> Rect
squareToRect' size' sq color' = Rect pointX' pointY' size' size'
  where pointX' = pointX $ toPos' size' sq color'
        pointY' = pointY $ toPos' size' sq color'

drawArrow :: DC a -> Int -> Square -> Square -> PColor -> IO ()
drawArrow dc size' s1 s2 perspective =
  drawArrowPt dc (pt (x1+size_half) (y1+size_half)) (pt (x2'+size_half) (y2'+size_half))
    where (Rect x1 y1 _ _ ) = squareToRect' size' s1 perspective
          (Rect x2 y2 _ _ ) = squareToRect' size' s2 perspective
          size_half = round $ fromIntegral size' / (2 :: Double)
          x2'
             | x2 > x1 = x2 - size_half
             | x2 < x1 = x2 + size_half
             | otherwise = x2
          y2'
             | y2 > y1 = y2 - size_half
             | y2 < y1 = y2 + size_half
             | otherwise = y2

drawArrowPt :: DC a -> Point -> Point -> IO ()
drawArrowPt dc p1 p2 = do
  line dc p1 p2 []
  polygon dc (fmap (movePt (pointX p2) (pointY p2) . rotate (dfix-90)) triangle) []
  where
    triangle = [(0, 0), (-2, -7), (2, -7)]
    movePt x y (Point px py) = pt (x + px) (y + py)
    deltaX = pointX p2 - pointX p1
    deltaY = pointY p2 - pointY p1
    d = atan(fromIntegral deltaY / fromIntegral deltaX) * 180 / pi
    dfix = if deltaX < 0 then d - 180 else d


rotate :: Double -> (Int, Int) -> Point
rotate d ptx = pt (round $ x * cos rad - y * sin rad) (round $ x * sin rad + y * cos rad)
  where x = fromIntegral $ fst ptx
        y = fromIntegral $ snd ptx
        rad = d/180*pi


