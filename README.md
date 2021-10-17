# 4thAxis-Libraries

Common libraries I contributed to over the years.  All of my written code is carefully optimized providing flexability for every tight-performance end implementations. 

## Design

Code is very self-documenting therefore I don't believe there is a need for documentation. Featuring important and commonly used functions for game development. 
All my math is carefully optimized for lower-ended architectures similar to ARM as they tend to lack necessary hardware optimizations to support certain arithmetic instructions
however if needed, computations are relied by macro preprocessing in hopes of potiental optimizations.

## Defensive Approach

Functions are designed to be defensive in the sense that a potentially propogated error can be accounted for while adjusting computational results or otherwise returning back 
warnings promoting future-proofed architecture therefore no dependencies of the libraries violate this belief. 

