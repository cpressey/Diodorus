module Language.Diodorus.Residuator where

import Debug.Trace

import Language.Diodorus.Model
import qualified Language.Diodorus.Env as Env

import qualified Language.Diodorus.Eval as Eval

data KnownStatus = Known Value
                 | Unknown
    deriving (Show, Ord, Eq)

type KEnv = Env.Env Name KnownStatus


isKnown :: Expr -> Bool
isKnown (Lit (Fun formals body env)) = Env.isEmpty env
isKnown (Lit _) = True
isKnown _ = False


residuateExpr :: KEnv -> KEnv -> Expr -> Expr
residuateExpr globals env app@(Apply e es) =
    let
        residuatedE = residuateExpr globals env e
        residuatedArgs = map (residuateExpr globals env) es
        eKnown = isKnown residuatedE
        argsKnown = all (isKnown) residuatedArgs
    in
        case (eKnown, argsKnown) of
            (True, True) ->
                let
                    value = Eval.evalExpr (Env.map (\(Known v) -> v) globals) Env.empty app
                in
                    Lit value
            _ ->
                app

residuateExpr globals env e@(Name n) = case Env.fetch n env of
    Just (Known v) -> Lit v
    _ -> case Env.fetch n globals of
        Just (Known v) -> Lit v
        _ -> e

residuateExpr globals env (Eval e) = error "not implemented: eval"

-- When we residuate a literal function, we install in it the current environment.
residuateExpr globals env e@(Lit (Fun formals body _)) =
    -- TODO when we descend into function literals,
    -- we need to extend the env with the formals
    -- which is something we do in the evaluator,
    -- but which we haven't done in the residuator yet
    trace (show (e, env)) (Lit (Fun formals body (Env.map (\(Known v) -> v) env)))

residuateExpr globals env other = other

-- All globals are known.

makeInitialEnv p = Env.map (\v -> Known v) $ Eval.makeInitialEnv p
