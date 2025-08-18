# Functional Programming Patterns in Haskell

> "The functional programming paradigm eliminates many of the errors that plague imperative code by emphasizing immutability and pure functions." — **Simon Peyton Jones**

## Introduction

Haskell represents one of the most *elegant* approaches to functional programming. This article explores **advanced patterns** that make Haskell both powerful and expressive.

### Why Functional Programming?

#### Benefits

1. **Immutability** prevents many classes of bugs
2. **Pure functions** are easier to reason about
   - No side effects to track
   - Deterministic behavior:
     ```haskell
     add :: Int -> Int -> Int
     add x y = x + y
     ```
3. **Type safety** catches errors at compile time
4. Composability leads to more maintainable code

#### Common Misconceptions

| Myth | Reality |
|------|---------|
| "Haskell is too academic" | Used in production at Facebook, GitHub |
| "Performance is poor" | Comparable to C++ in many cases |
| "Learning curve is steep" | Initial investment pays dividends |

### Getting Started

Here's a simple example of a pure function:

```haskell
factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)
```

## Core Concepts

### Pattern Matching

#### Basic Patterns

Pattern matching is fundamental to Haskell. Consider this list processing function:

```haskell
-- Process a list of integers
processInts :: [Int] -> String
processInts [] = "Empty list"
processInts [x] = "Single element: " ++ show x
processInts (x:y:xs) = "First two: " ++ show x ++ ", " ++ show y
```

#### Advanced Patterns

We can nest patterns for more complex data structures:

1. **Tree structures** with recursive patterns:
   ```haskell
   data Tree a = Leaf a | Branch (Tree a) (Tree a)
   
   treeDepth :: Tree a -> Int
   treeDepth (Leaf _) = 1
   treeDepth (Branch left right) = 1 + max (treeDepth left) (treeDepth right)
   ```

2. **Record patterns** for structured data:
   ```haskell
   data Person = Person { name :: String, age :: Int }
   
   greet :: Person -> String  
   greet Person{name = n, age = a} = "Hello " ++ n ++ ", age " ++ show a
   ```

### Higher-Order Functions

#### Function Composition

Functions that operate on other functions are central to functional programming:

- `map` applies a function to each element
- `filter` selects elements matching a predicate  
- `fold` reduces a structure to a single value

Here's how we might chain these operations:

```haskell
-- Transform a list of numbers
processNumbers :: [Int] -> Int
processNumbers = foldr (+) 0 . filter even . map (*2)
```

#### Custom Higher-Order Functions

1. **Conditional application**:
   ```haskell
   applyIf :: Bool -> (a -> a) -> a -> a
   applyIf condition f x = if condition then f x else x
   ```

2. **Function lifting**:
   ```haskell
   liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
   ```

## Advanced Patterns

### Monads and Do-Notation

#### Maybe Monad

The `Maybe` monad handles potential failure gracefully:

```haskell
safeDiv :: Double -> Double -> Maybe Double
safeDiv _ 0 = Nothing
safeDiv x y = Just (x / y)

calculation :: Double -> Double -> Double -> Maybe Double
calculation a b c = do
  x <- safeDiv a b
  y <- safeDiv x c
  return (y * 2)
```

#### IO Monad

File operations become composable:

1. **Reading files**:
   ```haskell
   processFile :: FilePath -> IO String
   processFile path = do
     content <- readFile path
     let processed = unlines . map reverse . lines $ content
     return processed
   ```

2. **Error handling**:
   ```haskell
   safeReadFile :: FilePath -> IO (Either String String)
   safeReadFile path = do
     result <- try (readFile path)
     case result of
       Left ex -> return $ Left (show ex)
       Right content -> return $ Right content
   ```

### Type Classes

#### Built-in Type Classes

Type classes provide *ad-hoc polymorphism*:

| Type Class | Purpose | Methods | Example Usage |
|------------|---------|---------|---------------|
| `Eq` | Equality testing | `==`, `/=` | `x == y` |
| `Ord` | Ordering | `<`, `>`, `compare` | `sort [3,1,2]` |
| `Show` | String representation | `show` | `show 42` |
| `Functor` | Mappable containers | `fmap` | `fmap (+1) [1,2,3]` |
| `Monad` | Sequenced computations | `>>=`, `return` | `do` notation |

#### Custom Type Classes

Create your own abstractions:

```haskell
class Drawable a where
  draw :: a -> String
  area :: a -> Double
  
instance Drawable Circle where
  draw (Circle r) = "Circle with radius " ++ show r
  area (Circle r) = pi * r * r

instance Drawable Rectangle where  
  draw (Rectangle w h) = "Rectangle " ++ show w ++ "x" ++ show h
  area (Rectangle w h) = w * h
```

### Lazy Evaluation

#### Infinite Structures

Haskell's lazy evaluation allows for infinite data structures:

1. **Fibonacci sequence**:
   ```haskell
   -- Infinite list of Fibonacci numbers
   fibs :: [Integer]
   fibs = 0 : 1 : zipWith (+) fibs (tail fibs)
   
   -- Take the first 10 Fibonacci numbers
   firstTenFibs = take 10 fibs
   -- Result: [0,1,1,2,3,5,8,13,21,34]
   ```

2. **Prime number sieve**:
   ```haskell
   primes :: [Int]
   primes = sieve [2..]
     where sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]
   ```

#### Performance Considerations

| Approach | Memory Usage | Performance |
|----------|--------------|-------------|
| Strict evaluation | Higher | Predictable |
| Lazy evaluation | Lower | Can cause space leaks |
| Bang patterns | Controlled | Best of both |

## Real-World Applications

### Web Development

#### Servant Framework

Modern Haskell web development often uses the Servant library:

```haskell
type API = "users" :> Get '[JSON] [User]
      :<|> "user" :> Capture "id" Int :> Get '[JSON] User
      :<|> "user" :> ReqBody '[JSON] User :> Post '[JSON] User

server :: Server API
server = getUsers :<|> getUser :<|> createUser
  where
    getUsers = return users
    getUser uid = return $ findUser uid users
    createUser user = do
      -- Database operations here
      return user
```

#### Database Integration

1. **Persistent library** for type-safe database operations:
   ```haskell
   share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
   User
       name String
       email String
       age Int Maybe
       deriving Show
   |]
   ```

2. **Query composition**:
   ```haskell
   findUsersByAge :: Int -> SqlPersistM [Entity User]
   findUsersByAge minAge = select $ 
     from $ \user -> do
     where_ (user ^. UserAge >=. val (Just minAge))
     return user
   ```

### Concurrent Programming

#### Software Transactional Memory

Haskell's STM makes concurrent programming safer:

```haskell
-- Bank account transfer using STM
data Account = Account { balance :: TVar Int, accountId :: String }

transfer :: Account -> Account -> Int -> STM ()
transfer from to amount = do
  fromBalance <- readTVar (balance from)
  toBalance <- readTVar (balance to)
  
  check (fromBalance >= amount)
  writeTVar (balance from) (fromBalance - amount)
  writeTVar (balance to) (toBalance + amount)

-- Usage in IO
main :: IO ()
main = do
  account1 <- Account <$> newTVarIO 1000 <*> pure "ACC1"
  account2 <- Account <$> newTVarIO 500 <*> pure "ACC2"
  atomically $ transfer account1 account2 200
```

#### Parallel Processing

1. **Par monad** for deterministic parallelism:
   ```haskell
   parallelMap :: (a -> b) -> [a] -> Par [b]
   parallelMap f xs = mapM (spawnP . f) xs >>= mapM get
   ```

2. **Async library** for concurrent IO:
   ```haskell
   fetchUrls :: [String] -> IO [String]
   fetchUrls urls = do
     asyncs <- mapM (async . httpGet) urls
     mapM wait asyncs
   ```

## Performance Optimization

### Strictness Annotations

Force evaluation with bang patterns:

```haskell
data Vector = Vector !Double !Double !Double

magnitude :: Vector -> Double
magnitude (Vector !x !y !z) = sqrt (x*x + y*y + z*z)
```

### Benchmarking

| Algorithm | Time Complexity | Space Complexity | Notes |
|-----------|----------------|------------------|-------|
| List sort | O(n log n) | O(n) | Built-in sort |
| Tree lookup | O(log n) | O(1) | Balanced trees |
| Hash lookup | O(1) average | O(1) | HashMap |

Common optimization techniques:

1. **Use appropriate data structures**:
   - `Vector` for numeric computation
   - `HashMap` for key-value lookups
   - `Sequence` for efficient concatenation

2. **Profile before optimizing**:
   ```bash
   ghc -prof -fprof-auto MyProgram.hs
   ./MyProgram +RTS -p
   ```

3. **Understand fusion**:
   ```haskell
   -- This fuses into a single pass
   sum . map (*2) . filter even $ [1..1000000]
   ```

### Memory Management

#### Avoiding Space Leaks

- Use `seq` to force evaluation
- Prefer tail-recursive functions
- Watch out for accumulating parameters:

```haskell
-- Space leak version
badSum :: [Int] -> Int
badSum [] = 0
badSum (x:xs) = x + badSum xs

-- Tail-recursive version  
goodSum :: [Int] -> Int
goodSum = go 0
  where go !acc [] = acc
        go !acc (x:xs) = go (acc + x) xs
```

## Conclusion

### Key Takeaways

Haskell's approach to functional programming offers:

1. **Mathematical foundations** that ensure correctness
2. **Expressive type system** that captures program logic
3. **Composable abstractions** that scale well
4. **Performance characteristics** suitable for real-world applications

### The Learning Journey

The transition from imperative to functional thinking requires patience, but rewards include:

- Fewer runtime errors
- More maintainable code  
- Better reasoning about program behavior
- Natural parallelization opportunities

### Next Steps

*For more advanced topics, consider exploring:*

- **Lens libraries** for elegant data manipulation
- **Free monads** for effect management  
- **Template Haskell** for compile-time metaprogramming
- **Dependent types** with recent GHC extensions

---

**References and Further Reading:**

| Book | Author | Focus Area |
|------|--------|------------|
| *Programming in Haskell* | Graham Hutton | Fundamentals |
| *Thinking Functionally with Haskell* | Richard Bird | Problem solving |
| *Real World Haskell* | O'Sullivan et al. | Practical applications |
| *Haskell Programming from First Principles* | Allen & Moronuki | Comprehensive guide |

### Online Resources

- **Documentation**: [Haskell.org](https://www.haskell.org)
- **Package repository**: [Hackage](https://hackage.haskell.org)  
- **Community**: [Reddit r/haskell](https://reddit.com/r/haskell)

> "Haskell is a language that rewards deep thinking and careful design. The investment in learning its abstractions pays dividends in code quality and developer productivity." — *The Haskell Community*