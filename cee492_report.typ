
#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Prediction of Concrete Compressive Strength Using Concrete Mixture Characteristics],
  abstract: [
    This project aims to investigate the relationships between concrete mixture characteristics, age, and compressive strength using exploratory data analysis and predictive modeling. Multiple statistical and machine-learning approaches will be evaluated to estimate concrete compressive strength and identify influential mixture characteristics. The findings are expected to provide insights into concrete strength development and inform future mixture design adjustments.
  ],
  authors: (
    (
      name: "Mohamed Alsaleh",
      department: [Department of Civil and Environmental Engineering],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "alsaleh4@illinois.edu",
    ),
    (
      name: "Jingchun Wang",
      department: [Department of Civil and Environmental Engineering],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "jw198@illinois.edu",
    ),
    (
      name: "Khwanjira Phumphid",
      department: [Department of Civil and Environmental Engineering],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "kp70@illinois.edu",
    ),
    (
      name: "Rae Zhu",
      department: [Department of Civil and Environmental Engineering],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "rzhu15@illinois.edu",
    ),
  ),
  index-terms: ("Concrete Compressive Strength", "Machine Learning", "Regression", "Feature Importance"),
  bibliography: bibliography(bytes(
    read("refs.bib") + "\n\n" +
    "@article{breiman2001,\n" +
    "  author = {Breiman, Leo},\n" +
    "  title = {Random Forests},\n" +
    "  journal = {Machine Learning},\n" +
    "  year = {2001},\n" +
    "  volume = {45},\n" +
    "  pages = {5--32},\n" +
    "  doi = {10.1023/A:1010933404324}\n" +
    "}\n" +
    "\n" +
    "@inproceedings{lundberg2017,\n" +
    "  author = {Lundberg, Scott M. and Lee, Su-In},\n" +
    "  title = {A Unified Approach to Interpreting Model Predictions},\n" +
    "  booktitle = {Advances in Neural Information Processing Systems},\n" +
    "  year = {2017},\n" +
    "  volume = {30},\n" +
    "  pages = {4765--4774}\n" +
    "}\n"
  )),
)

= *Dataset Description*

== *Dataset Source and Overview*

This project will use the Concrete Compressive Strength dataset available through the UCI Machine Learning Repository @yeh1998dataset. The dataset was originally provided by Prof. I-Cheng Yeh of Chung-Hua University. The data were developed from laboratory measurements of concrete mixtures, where the actual compressive strength of each mixture was determined at a specified age. The dataset is provided in raw, unscaled form and is available as an Excel file (Concrete_Data.xls), which can be downloaded from the #link("https://archive.ics.uci.edu/dataset/165/concrete+compressive+strength")[UCI Machine Learning Repository website] and is identified by the DOI #link("https://doi.org/10.24432/C5PK67")[10.24432/C5PK67].

The dataset contains 1,030 observations and nine quantitative variables. Eight variables describe the concrete mixture composition and age and are used as input variables. The ninth variable, concrete compressive strength, is the output variable. The dataset contains no missing values.

== *Dataset Variables*

@tab:variables summarizes the nine variables included in the dataset. The amounts of the seven mixture components are given in kilograms per cubic meter of concrete, the specimen age is given in days, and the compressive strength is given in MPa. Because this project aims to predict compressive strength from the mixture composition and age, the primary response variable will be *concrete compressive strength in MPa*, while the remaining eight variables will be considered potential predictors.

#figure(
  table(
    columns: (2fr, 1fr, 3fr, 1fr),
    inset: 3pt,
    align: (left, center, left, center),

    table.header(
      [*Variable*],
      [*Unit*],
      [*Description*],
      [*Role*],
    ),

    [Cement],
    [kg/m#super[3]],
    [Amount of cement in the concrete mixture],
    [Input],

    [Blast Furnace Slag],
    [kg/m#super[3]],
    [Amount of blast furnace slag in the mixture],
    [Input],

    [Fly Ash],
    [kg/m#super[3]],
    [Amount of fly ash in the mixture],
    [Input],

    [Water],
    [kg/m#super[3]],
    [Amount of water in the mixture],
    [Input],

    [Superplasticizer],
    [kg/m#super[3]],
    [Amount of superplasticizer in the mixture],
    [Input],

    [Coarse Aggregate],
    [kg/m#super[3]],
    [Amount of coarse aggregate in the mixture],
    [Input],

    [Fine Aggregate],
    [kg/m#super[3]],
    [Amount of fine aggregate in the mixture],
    [Input],

    [Age],
    [days],
    [Age of the concrete specimen at testing],
    [Input],

    [Concrete Compressive Strength],
    [MPa],
    [Measured compressive strength of the concrete],
    [Output],
  ),
  caption: [Description of dataset variables.],
) <tab:variables>

== *Exploratory Data Analysis*


@fig:raincloud shows the distribution of concrete compressive strength across different specimen ages. Overall, the median value of compressive strength increases with age, especially during the early stage. For example, the median compressive strength increases from approximately 16 MPa at 3 days to 34 MPa at 28 days, and continue to increase to 52 MPa at 56 days. However, the compressive strength varies within each age group. This variation existing within each age group suggests that curing age alone cannot fully explain the differences in compressive strength. 

In addition, the strength distributions across the different age groups do not necessarily show a consistent upward trend. For example, the 91-day group has a much higher median strength than the 90-day group. This difference does not necessarily indicate a sudden rise in strength, because the specimens tested at these ages may have different mixture compositions. The sample sizes are not consistent either: 425 specimens were tested at 28 days, while only 22 were tested at 91 days. Therefore,  comparisons across age groups may not be entirely valid, and the effects of mixture composition should also be considered.

#figure(
  image("figures/eda/fig1_raincloud_age.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Distribution of compressive strength by specimen age.],
) <fig:raincloud>

@fig:corner presents the pairwise relationships and Spearman’s rank correlation coefficients among the selected variables. Specimen age has the strongest positive correlation with compressive strength (ρ=0.60), followed by cement content (ρ=0.48) and high-performance water-reducing agent(superplasticizer) content (ρ=0.35). In contrast, water content showed a negative correlation with compressive strength (ρ=-0.31), suggesting that mixtures with higher water content tend to have lower strength. 

The relationships among the mixture components are also important. For example, fly ash and superplasticizer show a positive correlation (ρ = 0.45), while water and superplasticizer show a negative correlation (ρ = −0.69). These relationships indicate that some predictors are associated with each other, which should be considered when developing predictive models. Furthermore, the relationship between age and strength is described more accurately by the Spearman correlation coefficient (ρ = 0.60) than by the Pearson correlation coefficient (r = 0.33), indicating that this relationship may be monotonic but nonlinear.

#figure(
  image("figures/eda/fig2_corner.png", width: 80%),
  placement: auto,
  scope: "parent",
  caption: [Pairwise relationships and Spearman rank correlations among mixture variables, age, and compressive strength.],
) <fig:corner>

@fig:ternary illustrates the relationship between binder composition and 28-day concrete compressive strength using a ternary diagram of cement, blast furnace slag, and fly ash proportions. Comparing specimens at the same testing age allows the relationship between binder composition and compressive strength to be examined without differences in specimen age affecting the comparison. 

The figure shows that some mixtures with higher cement proportions achieve relatively high compressive strength. However, high strength is also observed in mixtures containing slag or fly ash, suggesting that partially replacing cement with these materials does not necessarily result in lower strength. Considerable variation in compressive strength is observed even among mixtures with similar binder proportions. This indicates that binder composition alone cannot fully explain the differences in strength. Other factors, such as water content, total binder content, and chemical admixtures, may also contribute to the observed variation. Therefore, multiple mixture characteristics should be considered when developing predictive models for concrete compressive strength.

#figure(
  image("figures/eda/fig3_ternary_binder.png", width: 100%),
  caption: [Binder composition and 28-day compressive strength.],
) <fig:ternary>

@fig:wb shows the relationship between the water-to-binder ratio and the concrete compressive strength, with specimen age represented by color. A clear decreasing trend can be observed, as mixtures with lower water-to-binder ratios typically achieve higher compressive strengths.  For example, specimens with water-to-binder ratios below approximately 0.35 exhibit strengths ranging from about 20 to over 80 MPa, while most specimens with ratios above 0.70 have strengths below 30 MPa. This relationship is consistent with the role of water in cement-based materials. This pattern is consistent with the understanding that excessive water relative to binder content can increase porosity and reduce concrete strength.

However, differences still exist among specimens with similar water-to-binder ratios. The color distribution indicates that specimens tested at later ages generally show achieve strength than those tested at earlier ages with comparable water-to-binder ratios. This indicates that both specimen age and water-to-binder ratio are associated with compressive strength. Other mixture characteristics may also explain some of the remaining variation. Therefore, the relationship should be interpreted as an association rather than evidence of a causal effect from this dataset alone.

#figure(
  image("figures/eda/fig4_wb_joint.png", width: 100%),
  caption: [Compressive strength versus water-to-binder ratio by specimen age.],
) <fig:wb>

@fig:development provides a more detailed analysis of strength development by tracking the change in strength over time for different concrete mixtures. Unlike @fig:raincloud, @fig:development (a) examines measurement data for the same mix design at multiple ages.
The strength of most mixtures increases rapidly during the early curing period, and the rate slows down later. Mixtures with lower water-to-binder ratios usually can achieve higher compressive strengths.

@fig:development (b) provides a more detailed comparison by normalizing the compressive strength of each mixture relative to 28-day strength. The normalized strength increases from approximately 0.46 at day 3 to 0.63 at day 7, and further to 0.82 at day 14. By approximately 90 days, the median reaches 1.25 indicating that the typical strength is about 25% higher than the corresponding 28-day value among the mixtures represented at that age. However, the shaded percentile ranges show variation in strength development across different mixtures. Therefore, while the general trend suggests increasing strength with age, the rate of development varies among mixture designs.
#figure(
  image("figures/eda/fig5_strength_development.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Strength development of individual concrete mixtures.],
) <fig:development>

Based on exploratory data analysis, the compressive strength of concrete depends on multiple factors rather than any single mix design characteristic. The age of the test specimens and the cement content are positively correlated with strength, while the water content and the water-to-binder ratio are negatively correlated.

= *Proposed Analysis*

The objective of this project is to investigate the relationships among concrete mixture characteristics, age, and compressive strength and to develop predictive models for concrete compressive strength. The first stage of the analysis will use exploratory data analysis to examine the variable distributions and relationships among the mixture components, age, and compressive strength. Appropriate graphical and statistical methods will be used to explore these relationships, while feature importance analysis will help identify which mixture characteristics are most strongly associated with compressive strength.

The second stage of the project will apply multiple predictive modeling approaches introduced in the course. These may include statistical regression methods and machine-learning models, as appropriate based on the methods covered during the semester. The models will be developed using the eight input variables and evaluated using appropriate prediction-performance measures. Their predictive capabilities will then be compared to determine how different statistical and machine-learning approaches perform in estimating concrete compressive strength. This analysis is useful because compressive strength is an important indicator of concrete performance, while strength development depends on several interacting mixture characteristics and the age of the concrete. Comparing multiple predictive approaches can also provide insight into whether more flexible machine-learning methods offer improved predictive performance compared with conventional statistical regression models. Furthermore, identifying the most influential mixture characteristics can provide insights into the factors associated with concrete strength and help guide future mixture design adjustments to improve concrete performance.

= *Predictive Modeling*

We will compare four models for concrete compressive strength: multiple linear regression, polynomial regression with ridge regularization, a regression tree, and random forest (RF). All models will use the seven mixture ingredients and age to predict strength in MPa. The aim is to assess whether more flexible models improve predictions for mixtures absent from the training data. The resulting models could support preliminary mixture assessment within the conditions represented by the dataset.

Multiple linear regression will provide the baseline. The polynomial model will include the eight original predictors, their squared terms, and pairwise interactions. A ridge penalty will limit coefficient size to reduce overfitting. The regression tree will divide observations through successive rules, while RF will average predictions from 500 trees built with random variation in observations and candidate predictors @breiman2001. The MLR analysis was implemented in Python, while the RF model and its SHAP explanations were implemented in Julia. The implementation language for each model is documented in its subsection.

The same data split will allocate approximately 80% of observations to training and 20% to testing. Records with identical quantities of the seven ingredients will stay together, including measurements at different ages. These mixture groups will be assigned intact, so the final percentages may differ slightly from 80/20. This approach will assess predictions for unseen recipes and prevent the same recipe from appearing in both sets. Repeated records will be reviewed before the split, and any corrections will apply to all models.

The three tunable models use grid search with 20 predefined parameter configurations each. Every configuration is evaluated through the same five mixture-grouped validation folds in the training set, with mixture groups kept intact. The predefined grids are:

- *Polynomial regression with ridge regularization:* 20 penalty values spaced evenly on a logarithmic scale from 0.0001 to 10,000.
- *Regression tree:* maximum depths of 3, 5, 8, 12, or no depth limit, combined with minimum leaf sizes of 2, 5, 10, or 20 observations.
- *RF:* maximum depths of 10 or no depth limit, minimum leaf sizes of 2 or 5 observations, and 2, 3, 4, 6, or 8 candidate predictors per split. The number of trees will remain fixed at 500.

These grids provide the same number of candidate evaluations for each tunable model, although the parameters and their ranges differ by model. Ordinary linear regression has no comparable tuning parameter and will be evaluated on the same validation folds. Data partitions and random seeds will be recorded and reused.

All models will use the same eight source predictors and untransformed strength values. Polynomial terms will be fixed before tuning. For the regression models, input columns will be standardized using means and standard deviations calculated from each training fold. The corresponding validation fold will receive the same transformation. Polynomial terms will be standardized after expansion. Trees will use unscaled inputs because their split rules do not require standardization. After tuning, scaling parameters will be recalculated from the full training set and applied unchanged to the test set.

Mean root mean squared error (RMSE) across the five predefined mixture-grouped validation folds determines hyperparameter selection. Ordinary random cross-validation is used only as a supplementary diagnostic, not for model selection. After selection, each tuned model is refitted to the full training set and evaluated once on the same held-out test observations. Test RMSE, mean absolute error (MAE), and $R^2$ will be reported, with RMSE and MAE expressed in MPa. Predicted-versus-observed and residual plots will show where errors occur. Test results will not guide further tuning or changes to preprocessing.

SHapley Additive exPlanations (SHAP) were used to interpret RF predictions @lundberg2017, with approximate Shapley values calculated in Julia using ShapML.jl. Training observations provided the reference data, and explanations covered held-out test observations after the RF hyperparameters were selected. Mean absolute SHAP values will rank predictor contributions. A summary plot and dependence plots for the leading predictors will show contributions to higher or lower predicted strength relative to the reference prediction. These results explain model behavior and do not establish causal effects. Correlated ingredients may affect how contributions are shared.

The model's predictive ability will be limited by the range and distribution of the available data. Predictions for mix proportions or curing ages that are poorly represented in the dataset may be less reliable. The interpretation of the model's performance should be limited to dataset.

== *Data Preparation and Partitioning*

Before modeling, the 1,030 records were checked for repeated entries. Twenty-five records were exact copies of another record in all nine variables and were removed, leaving 1,005 records from 428 unique mixtures. Nine combinations of mixture and age contain two records with different strength values. These records were kept because they represent separate test results rather than repeated entries.

The cleaned records were divided into training and test sets by mixture, as planned. Whole mixtures were assigned to the test set in random order until 20% of the records were reached (random seed 492). The training set contains 804 records from 341 mixtures, and the test set contains 201 records from 87 mixtures, with no mixture appearing in both sets. The training mixtures were then assigned to five validation folds of 160 or 161 records each. The strength distributions of the two sets are similar (mean of 35.4 MPa for training and 34.9 MPa for testing; two-sample Kolmogorov–Smirnov test, p = 0.94). The assignment of every record is stored in `data/concrete_split.csv`, and the same file is used for all four models.

== *Multiple Linear Regression*

Multiple linear regression (MLR) was fitted by ordinary least squares in Python. Following the plan, the baseline model used the eight source predictors. The inputs were standardized with the means and standard deviations of each training fold, so each coefficient represents the change in predicted strength (MPa) for an increase of one standard deviation in that predictor.

The exploratory analysis suggested two relationships that a linear model cannot represent with the source predictors alone. First, strength increases with age in a monotonic but nonlinear way (@fig:raincloud, @fig:development), so a straight-line age term is expected to fit poorly. Second, strength decreases with the water-to-binder ratio (@fig:wb), which is a ratio of four inputs rather than a linear combination of them. Therefore, four alternative feature sets were compared with the baseline: (1) age replaced by its natural logarithm, ln(age); (2) ln(age) together with the water-to-binder ratio, w/b = water/(cement + slag + fly ash); (3) the second set without the two aggregate variables, as a test of feature selection; and (4) the second set with ln(strength) as the response, with predictions transformed back to MPa. All feature sets were evaluated on the same five validation folds, and the set with the lowest mean validation RMSE was selected. The test set was used only once, after this selection.

@fig:mlr-features (a) and @tab:mlr summarize the comparison. The baseline model had a mean validation RMSE of 10.5 ± 0.7 MPa. Replacing age with ln(age) reduced this value to 7.4 ± 0.5 MPa, a reduction of 29%, and the improvement appeared in every validation fold. Adding w/b gave only a small further reduction (7.39 MPa), and this reduction was not consistent across folds. Removing the aggregates increased the error slightly (7.55 MPa), so the aggregate variables were kept. Transforming the response was not helpful: the ln(strength) model had a higher and less stable validation RMSE (9.4 ± 1.7 MPa). This is likely because fitting on the logarithmic scale gives less weight to errors at high strengths, which are the largest errors when measured in MPa. Based on the selection rule, the ln(age) + w/b feature set was chosen. On the test set, it achieved an RMSE of 6.8 MPa, an MAE of 5.2 MPa, and an $R^2$ of 0.81, compared with 10.4 MPa, 8.1 MPa, and 0.56 for the baseline. For reference, predicting the training mean for every specimen gives a test RMSE of 15.7 MPa.

#figure({
  set text(hyphenate: false)
  set par(justify: false)
  table(
    columns: (3.4fr, 0.45fr, 1.6fr, 0.95fr, 0.95fr, 0.85fr),
    inset: 3pt,
    align: (left, center, center, center, center, center),

    table.header(
      [*Feature set*],
      [*p*],
      [*Validation RMSE*],
      [*Test RMSE*],
      [*Test MAE*],
      [*Test $R^2$*],
    ),

    [Baseline], [8], [10.53 ± 0.72], [10.39], [8.10], [0.56],
    [ln(age) replaces age], [8], [7.43 ± 0.50], [6.81], [5.30], [0.81],
    [*ln(age) + w/b (selected)*], [*9*], [*7.39 ± 0.50*], [*6.77*], [*5.25*], [*0.81*],
    [ln(age) + w/b, no aggregates], [7], [7.55 ± 0.54], [6.56], [5.14], [0.83],
    [ln(strength) response], [9], [9.41 ± 1.70], [8.92], [6.19], [0.68],
    [Mean-only predictor], [0], [–], [15.72], [12.80], [0.00],
  )},
  caption: [Performance of multiple linear regression feature sets (p: number of predictors; RMSE and MAE in MPa; validation values are mean ± SD over five folds).],
) <tab:mlr>

@fig:mlr-features (b) compares the standardized coefficients of the baseline and selected models. The 95% confidence intervals are based on heteroscedasticity-robust (HC3) standard errors, because the spread of the residuals increases with predicted strength (Breusch–Pagan test, p < 0.001). In both models, cement, slag, and fly ash have positive coefficients, and cement has the largest effect among the ingredients. In the baseline model, an additional 1 kg/m#super[3] of cement is associated with 0.12 MPa higher strength, while an additional 1 kg/m#super[3] of water is associated with 0.11 MPa lower strength. In the selected model, ln(age) has the second-largest coefficient after cement (10.2 and 11.2 MPa per standard deviation, respectively) and the narrowest confidence interval. However, when w/b is included, the water coefficient is no longer significantly different from zero, because the effect of water is now shared with w/b. The variance inflation factors (VIF) also increase from a maximum of 8.0 in the baseline model to 24.5 for cement and 19.0 for w/b in the selected model. Therefore, the coefficients of the selected model should not be interpreted one at a time. The positive coefficients of the aggregates should also be interpreted with caution. Because the ingredient amounts together make up one cubic meter of concrete, these coefficients may reflect differences in the overall mixture design rather than a direct strengthening effect of the aggregates. This collinearity is one reason for the ridge penalty used in the polynomial model.

#figure(
  image("modeling/mlr/figures/mlr_feature_sets.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Feature-set comparison and standardized coefficients of multiple linear regression.],
) <fig:mlr-features>

@fig:mlr-diagnostics shows where the errors occur on the test set. The baseline model overpredicted the strength of young specimens (mean residual of −10.9 MPa at 3–7 days) and underpredicted specimens tested at 56–100 days (+8.2 MPa). This is the pattern expected when a curved strength-gain relationship is described by a straight line. The ln(age) term removed most of this pattern (−1.8 and +1.9 MPa for the same age groups). Two systematic errors remain. First, the 14 test specimens tested at 180–365 days were overpredicted by 6.4 MPa on average, because ln(age) keeps increasing while the measured strength levels off after about 90 days (@fig:development). Second, specimens stronger than 60 MPa were underpredicted by 5.0 MPa on average, with an RMSE of 10.5 MPa. In addition, the residuals are not normally distributed (Shapiro–Wilk test, p < 0.001), and their spread increases with predicted strength (@fig:mlr-diagnostics (c)).

#figure(
  image("modeling/mlr/figures/mlr_diagnostics.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Test-set diagnostics of the baseline and selected multiple linear regression models.],
) <fig:mlr-diagnostics>

To check whether these results depend on the particular split, the baseline and selected models were refitted on 200 alternative mixture-grouped 80/20 splits. The selected model had a median test RMSE of 7.2 MPa (5th–95th percentile: 6.4–8.1 MPa), compared with 10.5 MPa (9.6–11.3 MPa) for the baseline, and it was more accurate in all 200 splits. The test RMSE of 6.8 MPa from the main split is therefore slightly better than typical. The baseline model was also evaluated with ordinary random five-fold cross-validation, which ignores the mixture groups. The result (10.46 MPa) was almost identical to the grouped result (10.53 MPa). This suggests that grouping has little effect for a linear model, which cannot memorize individual recipes. More flexible models may behave differently, which is why the grouped split is kept for all models.

The selected MLR model reduces the error of the mean-only predictor by 57%, and 59% and 83% of the test predictions fall within ±5 MPa and ±10 MPa of the measured strength, respectively. However, an RMSE of 6.8 MPa is about 20% of the median 28-day strength in the dataset (34 MPa, @fig:raincloud), and the largest errors occur for high-strength mixtures and long curing ages. Therefore, the MLR model is useful for describing general trends and as a baseline for the other models, but it is not accurate enough to select a mixture that must meet a specific target strength. The diagnostics suggest that accuracy could be improved by an age term that levels off at long ages, by interaction terms between age and mixture composition, and by models that can represent nonlinear effects, such as the polynomial and tree-based models. Reading guides for @fig:mlr-features and @fig:mlr-diagnostics are provided as text files with the same names in the `modeling/mlr/figures/` folder.

== *Polynomial Regression with Ridge Regularization*

Polynomial regression with ridge regularization was used to examine whether adding nonlinear terms could improve concrete compressive strength prediction. The model started with the same eight predictors as the baseline MLR: cement, slag, fly ash, water, superplasticizer, coarse aggregate, fine aggregate, and specimen age. Squared terms and pairwise interactions were then added. This resulted in 44 predictors in total. The additional terms allow the model to represent curved relationships and interactions between mixture characteristics. However, they also introduce more correlated predictors. Ridge regression was therefore used to limit large coefficients and reduce overfitting.

The ridge model was fitted by minimizing the squared prediction errors together with a penalty on the squared coefficients. The intercept was not penalized. Following the original modeling plan, 20 penalty values between 0.0001 and 10,000 were considered on a logarithmic scale. Each value was evaluated using the same five mixture-grouped validation folds as the MLR model. Polynomial terms were expanded and then standardized using the mean and standard deviation calculated from each training fold. The same scaling was applied to the corresponding validation fold. This prevented information from the validation data from being used during model fitting.

Fig. 8 (a) shows the average validation RMSE for the 20 penalty values, while Fig. 8 (b) shows the RMSE for each fold at the selected penalty. The lowest mean validation RMSE was 8.42 ± 0.55 MPa at a penalty of λ = 11.29. After selecting this value, the polynomial expansion, scaling, and ridge model were fitted again using all 804 training observations. The final model was then evaluated on the 201 test observations, which were not used for parameter selection.

#figure(
  image("modeling/ridge/figures/ridge_tuning.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Ridge penalty selection. (a) Mean validation RMSE across 20 penalty values, with the shaded range showing one standard deviation across the five grouped folds. (b) Validation RMSE for each fold at the selected penalty.],
) <fig:ridge-tuning>


The polynomial ridge model achieved a test RMSE of 7.62 MPa, an MAE of 5.88 MPa, and an R² of 0.765. Compared with the original MLR using the eight source predictors (RMSE = 10.39 MPa), polynomial ridge reduced the test RMSE by approximately 27%. However, it did not perform as well as the selected MLR using ln(age) and the water-to-binder ratio (RMSE = 6.77 MPa). This suggests that simply adding quadratic and interaction terms was less effective than using the more targeted transformations identified in the exploratory analysis. Because the model uses many related polynomial terms, its individual coefficients should not be interpreted as separate physical effects.

Fig. 9 shows the model predictions and residuals on the test set. In Fig. 9 (a), most predicted strengths follow the observed values, although noticeable errors remain. About 53% of the predictions are within ±5 MPa, and 79% are within ±10 MPa. The residuals in Fig. 9 (b) also vary across specimen ages. For the 14 test specimens aged 180 days or more, the RMSE increased to 10.63 MPa, with a mean residual of −2.93 MPa. This indicates that the model tended to overpredict the strength of these older specimens. For the 14 specimens with measured strength above 60 MPa, the RMSE was 11.13 MPa and the mean residual was +3.67 MPa, indicating that the model tended to underpredict high strengths. These groups contain relatively few observations, so their error estimates should be interpreted with caution.

#figure(
  image("modeling/ridge/figures/ridge_diagnostics.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Test-set diagnostics for polynomial regression with ridge regularization. (a) Predicted versus observed strength. (b) Residuals by specimen age. (c) Residuals versus predicted strength.],
) <fig:ridge-diagnostics>

Overall, polynomial ridge regression improves the prediction compared with the original linear model and captures some nonlinear relationships among the concrete ingredients and age. However, its errors are still large for some older and high-strength specimens. Therefore, it may be useful for preliminary comparisons of mixtures within the range represented by the dataset, but it is not accurate enough to confirm that a concrete mixture meets a required design strength without laboratory testing. Among the two evaluated parametric regression approaches, the selected MLR has the lower test error. The RF results are presented below; the regression tree can be added to the full comparison once its results are available. Reading guides for @fig:ridge-tuning and @fig:ridge-diagnostics are provided as text files with the same names in the `modeling/ridge/figures/` folder.

== *Regression Trees*
The regression tree model was developed using Julia's DecisionTree.jl package.Regression trees perform recursive partitioning of observations based on the values of the independent variables, to minimize differences of compressive strength within each resulting group. Each terminal leaf node generates a predicted value based on the average strength of its training observations.

To control the model’s complexity, two hyperparameters were adjusted: the maximum tree depth and the minimum number of samples per leaf node.The maximum depth limits the number of splits, while the minimum leaf node size determines the minimum number of observations in each terminal node. A larger maximum depth and a smaller leaf node size allow the model to capture more complex relationships, but may lead to overfitting.

Five optional values are considered for the maximum tree depth (3, 5, 8, 12, and unlimited), while four possible values are considered for the minimum number of samples per leaf node (2, 5, 10, and 20,in total of 20 different hyperparameter combinations.Each combination was evaluated using 5-folds cross validation, and the combination with the lowest RMSE is selected for the final model.
#figure(
  image(
    "modeling/rt/rt_rmse_heatmap.png",
    width: 100%,
  ),
  caption: [
    Mean validation RMSE across 20 regression tree
    hyperparameter combinations using five-fold
    cross-validation.
  ],
) <fig:rtree-rmse>

As in @fig:rtree-rmse, with the maximum tree depth increased from 3 to 12, RMSE generally decreased, which also shows that deeper tree structures are more effective at modeling the complex relationships. A smaller minimum leaf node size also help to lower errors, especially with deeper tree structures.However, increasing the maximum tree depth over 12 did not make further improvements.Among the 20 hyperparameter combinations, the combination with a maximum depth of 12 and a minimum leaf node size of 2 achieved the lowest RMSE of 8.7 MPa.And the final regression tree using this combination was trained with full training set, followed by evaluation on the test set.

#figure(
  table(
    columns: (1fr, 1fr),
    align: (left, center),
    stroke: none,
    inset: (x: 8pt, y: 5pt),

    table.hline(stroke: 0.8pt),
    [*Metric*], [*Value*],
    table.hline(stroke: 0.5pt),

    [RMSE (MPa)], [6.756],
    [MAE (MPa)], [4.917],
    [$R^2$], [0.815],

    table.hline(stroke: 0.8pt),
  ),
  caption: [Regression tree performance on the testing set.],
) <tab:rtree-performance>
The predictive performance of the regression tree model was evaluated using RMSE, MAE, and R². As shown in @tab:rtree-performance, the model’s RMSE is 6.756 MPa, the MAE is 4.917 MPa, and R² is 0.815. 


#figure(
  placement: top,
  scope: "parent",
  [
    #image("modeling/rt/rt_predOb.png", width: 100%)

    #v(3pt)

    #grid(
      columns: (1fr, 1fr, 1fr),
      align: auto,
      [a],
      [b],
      [c],
    )
  ],
  caption: [
    Regression tree performance on the testing set:
    (a) observed versus predicted compressive strength;
    (b) residuals versus specimen age;
    and (c) residuals versus predicted compressive strength.
  ],
) <fig:rtree-performance>

@fig:rtree-performance(a) shows that most of the predicted compressive strengths are distributed near the 1:1 reference line, indicating consistency between the model’s predictions and the observed values. Most of the predicted values fall within an error band of ±10 MPa. However, some observed values differ significantly from the reference line, which means that the model’s predictive accuracy is lower for certain concrete mix designs.In @fig:rtree-performance(b), at different curing ages, the residuals are distributed on both sides of the zero-residual line. It can be told that the model does not consistently overestimate or underestimate the compressive strength across all curing ages.However, the Lowess trend gradually decreases as specimen age increases, which means it turns from underestimate to overestimate compressive strength when curing ages increase.Similarly, @fig:rtree-performance(c) shows that at lower and medium predicted strengths, the residuals are generally concentrated near zero, and at higher predicted strengths, the LOWESS trend shows an obvious downward slope. This suggests that the model may tend to overestimate compressive strength in higher predicted strength. 

To assess the relative importance of the eight input variables in the regression tree model, each feature was randomly permuted 30 times while keeping the remaining features constant. For each permutation, calculate the change in training RMSE relative to the performance of the original model. And the results are included in @fig:rt-feature-importance.
#figure(
  image("modeling/rt/rt_feature_importance.png", width: 100%),
  caption: [
    Permutation feature importance of the regression tree model.
    Points represent the mean change in training RMSE across
    30 random permutations.
  ],
) <fig:rt-feature-importance>
The cement content shows the highest feature importance, the average increase in RMSE is qround 14 MPa,followed by specimen age (12.7 MPa), water content (9.5 MPa), and slag content (7.3 MPa). The importance scores for the remaining four variables—fine aggregate, fly ash, coarse aggregate, and superplasticizer—are relatively smaller, ranging from 2 to 3 MPa. Shorter error bars may indicate that the importance estimates vary little across multiple permutations. These results suggest that the regression tree mainly depends on cement content, curing age, moisture content, and slag content to predict concrete compressive strength. However, it is important to note that the feature importance measures the model’s dependence on each feature, rather than the impact of these features on concrete strength.

This regression tree model, with eight input variables, performed well in predicting the compressive strength of concrete. By optimizing hyperparameters（maximun depth and minimum leaf node size）, the RMSE in the 5-folds cross-validation decreased from approximately 11.60 MPa for a shallow tree (maximum depth of 3 and minimum leaf node size of 2) to 8.70 MPa(maximum depth of 12 and minimum leaf node size of 2),reducing it by approximately 25%.
On the testing set, the final model had RMSE of 6.756 MPa, MAE of 4.917 MPa, and R² of 0.815, that means the model fits approximately 81.5% of the observed variation in compressive strength.On the testing set, the final model had RMSE of 6.756 MPa, MAE of 4.917 MPa, and R² of 0.815, that means the model fits approximately 81.5% of the observed variation in compressive strength.

While having such performance, there are still some limitations.The MAE of approximately 4.92 MPa indicates that prediction errors is still big; residual analysis shows a slight tendency to overestimate compressive strength at longer curing ages and higher predicted strength levels. Moreover, the predictions generated by a single regression tree will exhibit piecewise constant distribution, limits its ability to smoothly capture changes in compressive strength as input variables change.

== *Random Forest and SHAP Analysis*

Random forest (RF) regression was used to model nonlinear relationships among the seven concrete ingredients, specimen age, and compressive strength @breiman2001. The model was implemented in Julia with DecisionTree.jl and used the eight original predictors without scaling or additional feature transformations. To maintain comparability, the same 804 training observations, 201 held-out test observations, and five mixture-grouped validation folds were taken directly from `data/concrete_split.csv`. Each of 20 predefined combinations of maximum depth (10 or unrestricted), minimum leaf size (2 or 5), and candidate predictors per split (2, 3, 4, 6, or 8) was evaluated with 500 trees. Hyperparameters were selected solely by the *lowest mean RMSE across the five mixture-grouped validation folds*, with the same mixture excluded from the corresponding training fold. Ordinary random five-fold cross-validation was computed separately as a diagnostic and did not influence model selection.

@fig:rf-tuning compares these two validation strategies. The minimum grouped validation RMSE was *6.34 ± 0.89 MPa* (mean ± standard deviation across folds), obtained with unrestricted maximum depth, a minimum leaf size of two, and four candidate predictors per split. For this selected configuration, ordinary random cross-validation yielded *5.65 ± 0.74 MPa*. Its lower error is consistent with the possibility that ordinary random folds contain observations at different ages from mixtures also represented in training, thereby providing an easier prediction task. Accordingly, the grouped estimate better reflects the stated goal of predicting strength for unseen mixture recipes; the random-fold result was not used to choose hyperparameters.

#figure(
  image("figures/rf/fig_rf_tuning.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Random forest hyperparameter evaluation. (a) Mean RMSE ± one standard deviation across the five *mixture-grouped* validation folds, used for model selection. (b) Ordinary random five-fold cross-validation, shown as a supplementary diagnostic only. Each configuration contains 500 trees; the star identifies the configuration selected from panel (a).],
) <fig:rf-tuning>

The selected RF model was refitted using all 804 training observations and evaluated once on the 201 held-out test observations. It achieved an RMSE of *5.23 MPa*, an MAE of *3.91 MPa*, and an $R^2$ of *0.889* (@tab:rf-comparison). Its test RMSE was approximately 23% lower than that of the selected multiple linear regression (MLR) model (6.77 MPa) and approximately 31% lower than that of polynomial ridge regression (7.62 MPa). The lower test error supports the usefulness of flexible nonlinear predictions for this dataset, although the feature sets differ between the selected MLR and RF models and the comparison reflects only this particular held-out split.

#figure(
  table(
    columns: (2.5fr, 1fr, 1fr, 0.8fr),
    inset: 4pt,
    align: (left, center, center, center),
    table.header([*Model*], [*Test RMSE*], [*Test MAE*], [*Test $R^2$*]),
    [Selected MLR (ln(age) + w/b)], [6.77], [5.25], [0.81],
    [Polynomial ridge], [7.62], [5.88], [0.765],
    [*Random forest*], [*5.23*], [*3.91*], [*0.889*],
  ),
  caption: [Held-out test performance of the completed models on the same 201 observations. RMSE and MAE are expressed in MPa; the regression tree will be added to the final four-model comparison.],
) <tab:rf-comparison>

@fig:rf-diagnostics summarizes the RF test predictions and residuals. Predictions generally track the measured strengths, while errors remain larger for some high-strength specimens. For the 14 specimens with measured strength above 60 MPa, the RMSE increased to *10.07 MPa*, with a mean observed-minus-predicted residual of *+7.18 MPa*, indicating underprediction. In contrast, the 14 specimens tested at ages of at least 180 days had an RMSE of *4.91 MPa* and mean residual of *+0.64 MPa*, substantially smaller in magnitude than the long-age bias reported for the selected MLR model. Because these subgroups contain few observations, the numerical differences should not be generalized without further validation. Despite its improved overall accuracy, the RF model cannot replace laboratory strength testing when compliance with a specified design strength must be established.

#figure(
  image("figures/rf/fig_rf_test_diagnostics.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Random forest performance on the held-out test set (n = 201). (a) Predicted versus observed compressive strength, with the 1:1 line and a ±10 MPa band. (b) Observed-minus-predicted residuals by specimen age, with medians. (c) Residuals versus predicted strength, with dashed lines at ±10 MPa.],
) <fig:rf-diagnostics>

To interpret the fitted RF model, approximate SHapley Additive exPlanations (SHAP) were calculated in Julia using ShapML.jl @lundberg2017. A random sample of 100 training observations provided the reference distribution, and stochastic Shapley estimates were calculated for all 201 test observations, using 60 samples per feature. Mean absolute SHAP values were used to summarize global importance. The leading predictors were age (*31.7%* of summed mean absolute SHAP importance), cement (*27.0%*), and water (*14.0%*), followed by superplasticizer (*8.7%*) and slag (*7.9%*) (@fig:rf-importance). These percentages represent *relative contributions to the fitted model's predictions*, rather than proportions of explained variance or physical causal effects.

#figure(
  image("figures/rf/fig_rf_shap_importance.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Global random forest feature importance based on mean absolute approximate SHAP values across the 201 test observations. Values are normalized to sum to 100%.],
) <fig:rf-importance>

The SHAP summary (@fig:rf-summary) and dependence plots (@fig:rf-dependence) provide information about the direction and nonlinearity of these associations. Larger ages and cement contents generally contributed positively to predicted strength, whereas greater water content generally contributed negatively. Age contributions increased markedly at early curing ages and changed less at later ages, consistent with nonlinear strength development. Positive SHAP contributions were also associated with greater slag content in portions of the observed data. However, dependence patterns need not be monotonic for every observation, and the apparent predictor effects may partly reflect correlations and interactions among ingredients. Because ShapML.jl produces sampling-based approximations with a finite training reference sample, these SHAP values should be interpreted as estimates of the model's behavior, not exact or causal decompositions of concrete strength.

#figure(
  image("figures/rf/fig_rf_shap_summary.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [SHAP summary for the 201 held-out test observations. Each point represents one observation; its horizontal position indicates the estimated contribution to predicted compressive strength, while color represents the corresponding predictor value.],
) <fig:rf-summary>

#figure(
  image("figures/rf/fig_rf_shap_dependence.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [SHAP dependence plots for (a) specimen age, (b) cement, (c) water, and (d) slag. Vertical coordinates are estimated contributions to predicted strength (MPa); colors indicate the corresponding secondary predictor shown by each color scale.],
) <fig:rf-dependence>

Overall, RF outperformed the selected MLR and polynomial ridge models on the shared held-out test set and captured important nonlinear associations. Nonetheless, systematic underprediction of strengths above 60 MPa and the observational nature of the dataset limit its use for strength-based acceptance decisions. Validation on independent concrete mixture datasets, particularly with broader coverage of high-strength specimens, would be required before practical deployment. The tuning results, test predictions, subgroup analyses, and approximate SHAP values are retained in `modeling/rf/outputs/`, with the corresponding figures in `modeling/rf/`.
