# Bayesian Inference: Gibbs, Metropolis-Hastings and Variational Inference

## 中文概览

**项目定位：统计建模 / 贝叶斯推断 / 算法实现与验证。** 使用 base R 实现 Gibbs sampling、随机游走 Metropolis–Hastings 和均值场 CAVI，比较后验均值、90% 可信区间及收敛行为。

- **个人贡献**：独立课程项目，完成后验与全条件分布推导、采样器及 CAVI 实现、结果解释。整理时新增了解析后验对照和自动检查。
- **结果**：Gibbs 后验均值为 (2.7145, -3.1443)，MH 为 (2.7072, -3.1486)，解析结果为 (2.7103, -3.1456)。两组 CAVI 初始化均在 3 次更新后收敛，均值与解析解一致。
- **验证**：已在 R 4.5.2 重跑。检查两条 ELBO 序列非递减、CAVI 均值误差小于 1e-8、采样均值与解析均值之差位于五倍 batch-means Monte Carlo 标准误内。
- **范围**：模拟教学数据和可解析的二维高斯模型。它展示算法与验证方法，不代表复杂高维模型中的性能或部署经验。

## English documentation

Implement and compare three Bayesian inference methods on a bivariate Gaussian posterior with a correlated prior. A separate conjugate Normal–Gamma example derives a posterior predictive Student-t distribution.

### Results reproduced in R

| Method | Mean mu1 | Mean mu2 | Setup |
| --- | ---: | ---: | --- |
| Exact posterior | 2.710268 | -3.145637 | Gaussian precision-matrix solution |
| Gibbs | 2.714452 | -3.144269 | 1,000 updates; discard first 100 |
| Random-walk MH | 2.707242 | -3.148585 | 4,000 updates; discard first 200 |
| Mean-field CAVI | 2.710268 | -3.145637 | Two starts; 3 updates each |

MH acceptance rates are 43.05% and 42.725% for the two starts. Posterior summaries use the first sampling chain after burn-in. See [numeric results](results/posterior-summary.csv), [variance comparison](results/variance-comparison.csv) and [validation record](results/validation.txt).

![Gibbs trace plots](results/diagnostic-01.png)

![CAVI ELBO](results/diagnostic-05.png)

### Reproduce

From the repository root, run:

```sh
Rscript run_analysis.R
```

Only base R is required. The script recreates five diagnostic PNGs and numeric results. It was executed with R 4.5.2. To render the derivations separately, install Quarto and its R/knitr dependencies, then run `quarto render analysis.qmd`. Quarto rendering has not been tested in this environment.

### Interpretation

CAVI recovers the exact posterior means in this Gaussian example. Its independent factors omit the small posterior covariance and slightly understate marginal variances. The discrepancy is small here: this example does not demonstrate large variational approximation error. The ELBO is recorded up to a shared additive constant and is not a normalised log evidence.

Trace plots and numerical benchmark checks support this particular run. Full ESS/R-hat diagnostics and high-dimensional benchmarking are not included. A five-MCSE check is a reproducibility diagnostic, not proof of general convergence.

### Source and contribution

Individual MAST30027 Modern Applied Statistics coursework, University of Melbourne, 2026. Data are supplied simulated educational observations (100 scores, 100 group-x observations, 150 group-y observations). Original assignment instructions and identifying submission headers are omitted. No licence is assigned to the supplied data or course material.

See [review notes](docs/REVIEW.md) and [contributions](docs/CONTRIBUTIONS.md).
