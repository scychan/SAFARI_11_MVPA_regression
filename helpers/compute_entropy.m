function H = compute_entropy(p)

H = -sum(p .* log(p));