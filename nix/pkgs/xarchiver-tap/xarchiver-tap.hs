-- | Xarchiver Thunar Archive Plugin - An adapter that makes Thunar Archive Plugin call xarchiver.
module Main where

import System.Environment (getArgs)
import System.Posix (executeFile)

main :: IO ()
main = do
  (action : workdir : files) <- getArgs
  doAction action workdir files

doAction :: String -> String -> [String] -> IO ()
doAction "create" _workdir inputs = invokeXarchiver $ "--compress" : inputs
doAction "extract-here" workdir archives =
  invokeXarchiver $
    "--multi-extract" : "--extract-to" : workdir : archives
doAction "extract-to" _workdir archives = invokeXarchiver $ "--multi-extract" : archives
doAction act _ _ = error $ "Unknown or invalid use of action: " ++ act

-- | Replaces the current executable with xarchiver, passing the given arguments.
invokeXarchiver :: [String] -> IO ()
invokeXarchiver args = executeFile bin True args Nothing
  where
    bin = "xarchiver"
