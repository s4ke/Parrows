Es ist "`Factoring in Dark Ages"'.
\begin{code}
module MathObj.Primes.SimpleFactor where

import MathObj.Primes.Sieve
\end{code}

Wir fertigen eine längere Primzahlliste an und machen Testdivisionen. Eine Wahnvorstellung für einen Algebraiker, allerdings müssen wir nur die \emph{Länge} der Eingabe von unserem FFT faktorisieren und sie ist nicht so erschreckend groß.

Nun testen wir für alle Primzahlen kleiner als $\sqrt{n}$ ob sie unseres $n$ teilen.

\begin{code}
-- factor :: Integral a => a -> [a]
factor n = map (fromIntegral) $ factor' n $ takeWhile (<= (truncate $ sqrt $ fromIntegral n)) primes
    where 
      -- factor' :: Integral a => a -> [a] -> [a]
      factor' n [] = [n]
      factor' n (p:ps) | r==0 && n>=2 = p:(factor' m (p:ps))
                       | r/=0 && n>=2 = factor' n ps
                       | otherwise    = []
                       where (m, r) = divMod n p
\end{code}

% Testroutine:
% \begin{code}
% main = do
%   print $ factor 128
%   print $ factor 1267
%   print $ product $ factor 1267
% \end{code}