{-# LANGUAGE FlexibleContexts #-}
module Language.Durito.Parser where

import Text.ParserCombinators.Parsec

import qualified Language.Durito.Env as Env
import Language.Durito.Model


program = do
    fspaces
    ds <- many defn
    return $ Program ds

defn = do
    keyword "def"
    n <- name
    keyword "="
    x <- literal
    return (n, x)

literal = litFun <|> litQuote <|> litInt

litFun = do
    keyword "fun"
    keyword "("
    f <- sepBy (name) (keyword ",")
    keyword ")"
    keyword "->"
    e <- expr
    return $ Lit $ Fun f e Env.empty

litQuote = do
    keyword "<<"
    e <- expr
    keyword ">>"
    fspaces
    return $ Lit $ Quote e

litInt = do
    c <- digit
    cs <- many digit
    num <- return (read (c:cs) :: Integer)
    fspaces
    return $ Lit $ Int num

expr = (try literal) <|> (try exprApply) <|> (try exprEval) <|> exprName

exprApply = do
    e <- (try subExpr) <|> exprName
    keyword "("
    a <- sepBy (expr) (keyword ",")
    keyword ")"
    return $ Apply e a

exprName = do
    n <- name
    return $ Name n

exprEval = do
    keyword "eval"
    e <- expr
    return $ Eval e

subExpr = do
    keyword "("
    e <- expr
    keyword ")"
    return e

--

keyword s = do
    try (string s)
    fspaces

fspaces = do
    spaces
    return ()

name = do
    c <- lower
    s <- many (alphaNum)
    fspaces
    return (c:s)

--

parseDurito text = parse program "" text

parseLiteral text = case parse literal "" text of
    Right (Lit v) -> v
    other -> error ("cannot parse literal: " ++ show other)