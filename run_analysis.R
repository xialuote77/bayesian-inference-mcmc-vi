# Run from the repository root: Rscript run_analysis.R
# Original base-R algorithms extracted from the student's completed QMD.
# Portfolio additions: output management, exact benchmark and numeric checks.
dir.create("results", showWarnings=FALSE)
X <- scan("data/scores.txt", quiet=TRUE)
x <- scan("data/group-x.txt", quiet=TRUE)
y <- scan("data/group-y.txt", quiet=TRUE)
stopifnot(length(X)==100L, length(x)==100L, length(y)==150L)
png("results/diagnostic-%02d.png",width=1400,height=1000,res=150)
post_shape <- 2 + length(X)/2
post_rate <- 1 + sum((X - 75)^2)/2
c(shape = post_shape, rate = post_rate)


sqrt(post_rate/post_shape)


set.seed(123)
n_iter <- 1000
xbar <- mean(x)
ybar <- mean(y)

gibbs <- function(init, n_iter) {
  chain <- matrix(NA_real_, nrow = n_iter + 1, ncol = 2)
  colnames(chain) <- c("mu1", "mu2")
  chain[1, ] <- init
  for (t in 1:n_iter) {
    chain[t+1, 1] <- rnorm(1, (100*xbar-2*chain[t, 2])/103, sqrt(1/103))
    chain[t+1, 2] <- rnorm(1, (300*ybar-2*chain[t+1, 1])/303, sqrt(1/303))
  }
  chain
}

chain1 <- gibbs(c(0, 0), n_iter)
chain2 <- gibbs(c(2, -1), n_iter)


cols <- c("#7B3FBF", "#D55E00")
layout(matrix(1:3, ncol = 1), heights = c(4, 4, 0.65))
par(las = 1, mgp = c(2.2, 0.6, 0))

for (j in 1:2) {
  par(mar = if (j == 1) c(2, 4, 2, 1) else c(3.5, 4, 2, 1))
  ylim_j <- range(chain1[-1, j], chain2[-1, j])
  plot(1:n_iter, chain1[-1, j], type = "l",
       col = cols[1], lwd = 0.8, ylim = ylim_j,
       xlab = if (j == 2) "Iteration" else "",
       ylab = colnames(chain1)[j],
       main = paste("Gibbs trace plot:", colnames(chain1)[j]),
       yaxt = if (j == 2) "n" else "s")
  lines(1:n_iter, chain2[-1, j], col = cols[2], lwd = 0.8)
  if (j == 2) axis(2, at = seq(-3.3, -3.0, 0.1), las = 1)
}

par(mar = c(0, 0, 0, 0))
plot.new()
legend("center", legend = c("Chain 1", "Chain 2"),
       col = cols, lty = 1, lwd = 1.5,
       horiz = TRUE, bty = "n", cex = 0.9)

layout(1)
par(mar = c(5, 4, 4, 2) + 0.1, las = 0, mgp = c(3, 1, 0))


burn_in <- 100
gibbs_samples <- chain1[-(1:(burn_in+1)),]

post_means <- colMeans(gibbs_samples)
cred_intervals <- apply(gibbs_samples, 2, quantile, probs = c(0.05, 0.95))

round(rbind(Mean = post_means,
            Lower90 = cred_intervals[1,],
            Upper90 = cred_intervals[2,]), 4)


par(mfrow = c(1, 2), mar = c(4, 4, 2.5, 1), las = 1,
    cex.axis = 0.9, cex.lab = 0.95, cex.main = 0.95)

for (j in 1:2) {
  d <- density(gibbs_samples[, j])
  plot(d, col = "#7B3FBF", lwd = 2,
       main = paste("Posterior density:", colnames(gibbs_samples)[j]),
       xlab = colnames(gibbs_samples)[j], ylab = "Density")
  abline(v = post_means[j], col = "#626772", lty = 2, lwd = 1.5)
}
par(mfrow = c(1, 1), las = 0, cex.axis = 1, cex.lab = 1, cex.main = 1)


set.seed(456)
n_mh <- 4000

log_target <- function(z) {
  -0.5 * (100*(z[1]-xbar)^2 + 300*(z[2]-ybar)^2 + 3 *z[1]^2
          + 4*z[1]*z[2] + 3*z[2]^2)
}

mh <- function(init, n_iter) {
  chain <- matrix(NA_real_, nrow = n_iter+1, ncol = 2)
  colnames(chain) <- c("mu1", "mu2")
  chain[1, ] <- init
  accepted <- 0
  
  for (t in 1:n_iter) {
    current <- chain[t, ]
    proposal <- rnorm(2, mean = current, sd = 0.1)
    log_ratio <- log_target(proposal) - log_target(current)
    
    if (log(runif(1)) < log_ratio) {
      chain[t+1, ] <- proposal
      accepted <- accepted + 1
    } else {
      chain[t+1, ] <- current
    }
  }
  list(chain = chain, acceptance = accepted/n_iter)
}

mh1 <- mh(c(0, 0), n_mh)
mh2 <- mh(c(2, -1), n_mh)
c(Chain1 = mh1$acceptance, Chain2 = mh2$acceptance)


cols <- c("#7545B5", "#D55E00")
layout(matrix(1:3, ncol = 1), heights = c(4, 4, 0.65))
par(las = 1, mgp = c(2.2, 0.6, 0))

for (j in 1:2) {
  par(mar = if (j == 1) c(2, 4, 2, 1) else c(3.5, 4, 2, 1))
  ylim_j <- range(mh1$chain[, j], mh2$chain[, j])
  
  plot(0:n_mh, mh1$chain[, j], type = "l", col = cols[1],
       lwd = 0.8, ylim = ylim_j,
       xlab = if (j == 2) "Iteration" else "",
       ylab = colnames(mh1$chain)[j],
       main = paste("MH trace plot:", colnames(mh1$chain)[j]))
  lines(0:n_mh, mh2$chain[, j], col = cols[2], lwd = 0.8)
  abline(v = 200, col = "grey", lty = 2, lwd = 1.5)
}

par(mar = c(0, 0, 0, 0))
plot.new()
abline(v = 200, col = "grey", lty = 2, lwd = 1.5)
legend("center", c("Chain 1", "Chain 2"), col = cols,
       lty = 1, lwd = 1.5, horiz = TRUE, bty = "n", cex = 0.9)


layout(1)
par(mar = c(5, 4, 4, 2) + 0.1, las = 0, mgp = c(3, 1, 0))


burn_mh <- 200
mh_samples <- mh1$chain[-(1:(burn_mh+1)), ]

mh_means <- colMeans(mh_samples)
mh_intervals <- apply(mh_samples, 2, quantile, probs = c(0.05, 0.95))

round(rbind(Mean = mh_means, Lower90 = mh_intervals[1, ],
            Upper90 = mh_intervals[2, ]), 4)


par(mfrow = c(1, 2), mar = c(4, 4, 2.5, 1), las = 1,
    cex.axis = 0.9, cex.lab = 0.95, cex.main = 0.95)

for (j in 1:2) {
  d <- density(mh_samples[, j])
  plot(d, col = "#7545B5", lwd =2,
       main = paste("MH posterior density:", colnames(mh_samples)[j]),
       xlab = colnames(mh_samples)[j], ylab = "Density")
  abline(v = mh_means[j], col = "#626772", lty = 2, lwd = 1.5)
}

par(mfrow = c(1, 1), las = 0, cex.axis = 1, cex.lab =1 , cex.main = 1)


elbo <- function(m1, m2) {
  -103*m1^2/2 - 303*m2^2/2 - 2*m1*m2 +
    100*xbar*m1 + 300*ybar*m2
}

cavi <- function(init, max_iter = 100, tol = 1e-5) {
  m1 <- init[1]
  m2 <- init[2]
  history <- elbo(m1, m2)

  for (t in 1:max_iter) {
    m1 <- (100*xbar - 2*m2)/103
    m2 <- (300*ybar - 2*m1)/303
    history <- c(history, elbo(m1, m2))
    if (abs(history[length(history)] -
            history[length(history)-1]) < tol) break
  }

  list(mean = c(mu1 = m1, mu2 = m2),
       variance = c(mu1 = 1/103, mu2 = 1/303),
       elbo = history, iterations = length(history)-1)
}

vi1 <- cavi(c(0, 0))
vi2 <- cavi(c(2, -1))

results <- data.frame(
  Run = c("Run 1", "Run 2"),
  Initial_mu1 = c(0, 2),
  Initial_mu2 = c(0, -1),
  Iterations = c(vi1$iterations, vi2$iterations),
  Mean_mu1 = c(vi1$mean[1], vi2$mean[1]),
  Mean_mu2 = c(vi1$mean[2], vi2$mean[2]),
  ELBO = c(tail(vi1$elbo, 1), tail(vi2$elbo, 1))
)
print(results, row.names = FALSE, digits = 8)


cols <- c("#7545B5", "#D55E00")
ylim_elbo <- range(vi1$elbo, vi2$elbo)

par(mfrow = c(1, 2), mar = c(4, 4, 2.5, 1),
    las = 1, cex.axis = 0.9, cex.lab = 0.95, cex.main = 0.95)

plot(0:vi1$iterations, vi1$elbo, type = "b", pch = 16,
     col = cols[1], lwd = 2, ylim = ylim_elbo,
     xlab = "Iteration", ylab = "ELBO", main = "CAVI: Run 1")

plot(0:vi2$iterations, vi2$elbo, type = "b", pch = 16,
     col = cols[2], lwd = 2, ylim = ylim_elbo,
     xlab = "Iteration", ylab = "ELBO", main = "CAVI: Run 2")

par(mfrow = c(1, 1), las = 0,
    cex.axis = 1, cex.lab = 1, cex.main = 1)


c(Run1 = all(diff(vi1$elbo) >= -1e-10),
  Run2 = all(diff(vi2$elbo) >= -1e-10))

runs <- list(vi1, vi2)
best <- which.max(sapply(runs, function(z) tail(z$elbo, 1)))
best_run <- runs[[best]]

cat("Selected run:", best, "\n")
cat("Initial values:",
    if (best == 1) "(0, 0)" else "(2, -1)", "\n")
cat("Iterations:", best_run$iterations, "\n")
cat("Final ELBO:", tail(best_run$elbo, 1), "\n")
print(round(best_run$mean, 6))
print(round(best_run$variance, 6))

dev.off()
# Analytic posterior benchmark for the bivariate Gaussian model.
precision <- matrix(c(103,2,2,303),2,2)
exact_cov <- solve(precision)
exact_mean <- as.vector(exact_cov %*% c(100*xbar,300*ybar))
stopifnot(max(abs(vi1$mean-exact_mean))<1e-8,
          max(abs(vi2$mean-exact_mean))<1e-8,
          all(diff(vi1$elbo)>=-1e-10),all(diff(vi2$elbo)>=-1e-10))
# Batch-means Monte Carlo standard errors retain serial dependence within batches.
mcse <- function(z) {
 k <- floor(sqrt(length(z))); nb <- floor(length(z)/k)
 batches <- colMeans(matrix(z[seq_len(k*nb)],nrow=k,ncol=nb))
 sd(batches)/sqrt(nb)
}
summary_rows <- function(name, draws) {
 se <- apply(draws,2,mcse); means <- colMeans(draws)
 stopifnot(all(abs(means-exact_mean)<5*se))
 data.frame(method=name,parameter=c("mu1","mu2"),mean=means,
 lower90=apply(draws,2,quantile,.05),upper90=apply(draws,2,quantile,.95),mcse=se)
}
ans <- rbind(summary_rows("Gibbs",gibbs_samples),summary_rows("Metropolis-Hastings",mh_samples),
 data.frame(method="Exact",parameter=c("mu1","mu2"),mean=exact_mean,
 lower90=exact_mean+qnorm(.05)*sqrt(diag(exact_cov)),upper90=exact_mean+qnorm(.95)*sqrt(diag(exact_cov)),mcse=NA),
 data.frame(method="CAVI",parameter=c("mu1","mu2"),mean=as.vector(vi1$mean),
 lower90=vi1$mean+qnorm(.05)*sqrt(vi1$variance),upper90=vi1$mean+qnorm(.95)*sqrt(vi1$variance),mcse=NA))
write.csv(ans,"results/posterior-summary.csv",row.names=FALSE)
write.csv(data.frame(parameter=c("mu1","mu2"),exact_variance=diag(exact_cov),vi_variance=vi1$variance),"results/variance-comparison.csv",row.names=FALSE)
writeLines(c(paste("R version:",getRversion()),"Exact CAVI mean checks: PASS","Both ELBO sequences nondecreasing: PASS","Both Monte Carlo means within five batch-means MCSE of exact target: PASS",paste("MH acceptance:",mh1$acceptance,mh2$acceptance)),"results/validation.txt")
print(ans)
