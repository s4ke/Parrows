\begin{code}
module MathObj.Residue.RootOfUnity where

import MathObj.Primes.SimpleFactor (factor)
import MathObj.Primes.SimplePrimeTest (isPrime)
import MathObj.Residue.Power
\end{code}

Hier suchen wir nach primitiven Einheitswurzeln modulo n. Es ist etwas einfacher, wenn n prim ist, wir schreiben dafuer p. Eigentlich brauchen wir auch die eulerische Funktion hier, aber $\phi(p)=p-1$. Ist p nicht prim, sind wir hier FALSCH!
\begin{code}
phi p | isPrime p = p-1
      | otherwise = error "p is not prime!" -- TODO
\end{code}

Z_p^* = Z_p \ {0} fuer prime p
\begin{code}
ps p = factor $ phi p 
\end{code}

Nun fuer jedes m in der Liste von Elementen von Z_p^* berechnen wir die Liste `mList m` == m^{\phi(p)/p_i}, wo p_i Elemente der Liste `ps p` sind.
\begin{nocode}
mList m p = [powM m k p | k<-div (phi p) ((ps p)!!i) , i<-[0..length (ps p) - 1] ]
\end{nocode}
\begin{code}
-- mList :: Integral a => a -> a -> a
-- wrong?
mList m p = let exponents = map (div (phi p)) $ ps p
            in map(\k -> powM m k p) exponents
\end{code}

Das keinste m fuer das `mList m` keine 1 enthaellt ist das Einheitswurtzel. Alle anderen solchen $m$ eigentlich auch.
\begin{code}
rootOfUnityModulo p = head $ filter (isRoot p) [1..p-1]

isRoot p m = not $ any (==1) $ mList m p
\end{code}