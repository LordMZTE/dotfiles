{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_GHC -Wno-incomplete-patterns #-}
{-# OPTIONS_GHC -Wno-incomplete-uni-patterns #-}

-- | This script acts as a wrapper around xplr to use it as a file chooser using
-- xdg-desktop-portal-termfilechooser (xdptf).
module Main where

import Control.Monad (void)
import Data.String (IsString (fromString))
import Data.Text (replace, unpack)
import System.Environment (getArgs)
import System.Process (spawnProcess, waitForProcess)

main :: IO ()
main = do
  args <- getArgs
  let (boolflags, path : out : _) = splitAt 3 args
  let [multiple, directory, save] = getBoolArg <$> boolflags
  let title = titleFor multiple directory save
  runXplr title path out directory

getBoolArg :: String -> Bool
getBoolArg "0" = False
getBoolArg "1" = True

titleFor :: Bool -> Bool -> Bool -> String
titleFor multiple directory save =
  concat
    [ "XDP Filechooser [",
      (if multiple then "M" else []),
      (if directory then "D" else []),
      (if save then "S" else []),
      "]"
    ]

runXplr :: String -> String -> String -> Bool -> IO ()
runXplr title path outfile directory =
  void $
    ( spawnProcess
        "foot"
        [ "--title",
          title,
          "--",
          "sh",
          "-c",
          "xplr "
            ++ (if directory then "--print-pwd-as-result " else [])
            ++ (shellEscape path)
            ++ " > "
            ++ (shellEscape outfile)
        ]
    )
      >>= waitForProcess
  where
    shellEscape :: String -> String
    shellEscape s =
      if '\'' `elem` s || '"' `elem` s || ' ' `elem` s
        then '\'' : unpack (replace "'" "\'" (fromString s)) ++ "'"
        else s
