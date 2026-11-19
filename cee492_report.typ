
#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Prediction of Concrete Compressive Strength Using Concrete Mixture Characteristics],
  abstract: [
    Compressive strength is the main property used to specify and accept structural concrete, but it is normally measured on specimens that have been cured for several weeks. This project examined how accurately the strength of previously unseen concrete mixtures can be predicted from their mixture proportions and age, using the 1,030 laboratory records of the UCI Concrete Compressive Strength dataset. Exploratory data analysis showed that strength increases nonlinearly with age, decreases with the water-to-binder ratio, and depends on several correlated ingredients, and that many mixtures were tested at more than one age. Four models were therefore compared on a data split that kept each mixture entirely in either the training or the test set: multiple linear regression, polynomial regression with ridge regularization, a regression tree, and a random forest. A logarithmic transformation of age reduced the error of linear regression by about 30%, and the random forest achieved the lowest error, with a test root mean squared error of 5.2 MPa and a coefficient of determination of 0.89. The errors remain large for specimens stronger than 60 MPa. Therefore, the models are suitable for preliminary screening of candidate mixtures but cannot replace laboratory strength testing.
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
  bibliography: bibliography("refs.bib"),
)

= *Introduction* <sec:intro>

Compressive strength is the property most commonly used to specify, design, and accept structural concrete. It is usually measured by testing cast specimens after a curing period, most often 28 days, so the strength of each trial mixture is known only after weeks of waiting and laboratory work. Modern concrete also contains supplementary cementitious materials, such as blast furnace slag and fly ash, and chemical admixtures, such as superplasticizer, in addition to cement, water, and aggregates. The documentation of the dataset used in this project describes the strength of such concrete as a highly nonlinear function of age and ingredients @yeh1998dataset, which makes it difficult to estimate from simple rules. A model that reliably predicts strength from the mixture proportions and age could therefore help engineers screen candidate mixtures and reduce the number of trial batches that must be cast and tested.

Data-driven prediction of concrete strength has been studied for several decades. Yeh, who donated the dataset used in this project, modeled the strength of high-performance concrete with artificial neural networks @yeh1998ann. Since then, many machine-learning methods have been applied to the problem. Chou et al. compared machine-learning techniques for simulating concrete strength using data from several countries @chou2014, and Feng et al. applied an adaptive boosting approach to compressive strength prediction @feng2020. Young et al. used statistical analysis and machine-learning methods to examine whether compressive strength can be estimated from knowledge of the mixture proportions alone @young2019. Ben Chaabene et al. reviewed this growing body of work on the machine-learning prediction of the mechanical properties of concrete @benchaabene2020.

Two characteristics of this dataset need attention when such models are evaluated. First, many mixtures were tested at several ages, so the 1,030 records contain only 428 different recipes (@sec:eda). If the records are split at random, the same recipe can appear in both the training and the test data, and the test then measures how well a model recalls known recipes rather than how well it predicts new ones. Second, the relationships among strength, age, and the ingredients are nonlinear, and the ingredients are correlated with each other, which affects linear and flexible models in different ways. This project therefore evaluated all models on a split that keeps every mixture entirely in either the training or the test set, and it used the exploratory analysis to guide the choice of input features.

The research question of this project is: _how accurately can the compressive strength of a previously unseen concrete mixture be predicted from its mixture proportions and age, and is this accuracy sufficient for preliminary mixture assessment?_ Based on the nonlinear patterns found in the exploratory analysis, it was hypothesized that (1) transforming the inputs according to known strength-development behavior would substantially improve a linear model, and (2) flexible tree-based models would predict unseen mixtures more accurately than linear regression. To test these hypotheses, four models of increasing flexibility were compared: multiple linear regression, polynomial regression with ridge regularization, a regression tree, and a random forest.

The remainder of this report is organized as follows. The rest of this section describes the dataset. @sec:eda presents the exploratory data analysis and the characteristics of the data that shaped the modeling choices. @sec:modeling describes the validation design and the four predictive models and compares their performance. Finally, @sec:discussion discusses whether the results answer the research question, whether the accuracy is high enough to be useful, and what could be done next.

== *Dataset* <sec:dataset>

This project uses the Concrete Compressive Strength dataset from the UCI Machine Learning Repository @yeh1998dataset. The dataset was donated by Prof. I-Cheng Yeh of Chung-Hua University and was developed from laboratory measurements of concrete mixtures, in which the compressive strength of each mixture was determined at a specified age. It is provided in raw, unscaled form as an Excel file (Concrete_Data.xls), which can be downloaded from the #link("https://archive.ics.uci.edu/dataset/165/concrete+compressive+strength")[UCI Machine Learning Repository website] and is identified by the digital object identifier (DOI) #link("https://doi.org/10.24432/C5PK67")[10.24432/C5PK67].

The dataset contains 1,030 observations of nine quantitative variables and has no missing values. @tab:variables describes each variable. The amounts of the seven mixture components (cement, blast furnace slag, fly ash, water, superplasticizer, coarse aggregate, and fine aggregate) are given in kilograms per cubic meter of concrete, the specimen age at testing is given in days, and the compressive strength is given in MPa. Because this project aims to predict strength from the mixture composition and age, concrete compressive strength is the response variable, and the remaining eight variables are the potential predictors. In this report, the combined mass of cement, slag, and fly ash is referred to as the binder. The dataset does not record the type of cement, the properties of the aggregates, or the curing conditions, so the effects of these factors cannot be modeled.

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
    [Age of the concrete specimen at testing (1 to 365 days)],
    [Input],

    [Concrete Compressive Strength],
    [MPa],
    [Measured compressive strength of the concrete],
    [Output],
  ),
  caption: [Description of dataset variables.],
) <tab:variables>

= *Exploratory Data Analysis* <sec:eda>

This section examines the distributions of the variables, their relationships with compressive strength, and the structure of the records. The aim was to identify the patterns that a predictive model needs to capture and the characteristics of the data that could cause problems during modeling.

@fig:raincloud shows the distribution of concrete compressive strength across different specimen ages. Overall, the median compressive strength increases with age, especially during the early stage. For example, the median strength increases from approximately 16 MPa at 3 days to 34 MPa at 28 days, and it continues to increase to 52 MPa at 56 days. However, the strength varies widely within each age group. This variation suggests that curing age alone cannot fully explain the differences in compressive strength.

In addition, the strength distributions across the age groups do not show a consistent upward trend. For example, the 91-day group has a much higher median strength than the 90-day group. This difference does not necessarily indicate a sudden rise in strength, because the specimens tested at these ages may have different mixture compositions. The sample sizes are also uneven: 425 specimens (41% of the records) were tested at 28 days, while only 22 were tested at 91 days and only 2, 3, and 6 were tested at 1, 120, and 360 days, respectively. Therefore, comparisons across age groups may not be entirely valid, and the effects of mixture composition should also be considered.

#figure(
  image("figures/eda/fig1_raincloud_age.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Distribution of compressive strength by specimen age.],
) <fig:raincloud>

@fig:corner presents the pairwise relationships and Spearman rank correlation coefficients among the selected variables. Specimen age has the strongest positive correlation with compressive strength (ρ = 0.60), followed by cement content (ρ = 0.48) and the content of superplasticizer, a high-range water-reducing admixture (ρ = 0.35). In contrast, water content is negatively correlated with compressive strength (ρ = −0.31), which suggests that mixtures with higher water content tend to have lower strength.

The relationships among the mixture components are also important. For example, fly ash and superplasticizer show a positive correlation (ρ = 0.45), while water and superplasticizer show a negative correlation (ρ = −0.69). These relationships indicate that some predictors are associated with each other, which should be considered when developing predictive models. Furthermore, the relationship between age and strength is described more accurately by the Spearman correlation coefficient (ρ = 0.60) than by the Pearson correlation coefficient (r = 0.33), which indicates that this relationship is monotonic but nonlinear.

#figure(
  image("figures/eda/fig2_corner.png", width: 80%),
  placement: auto,
  scope: "parent",
  caption: [Pairwise relationships and Spearman rank correlations among mixture variables, age, and compressive strength.],
) <fig:corner>

@fig:ternary illustrates the relationship between binder composition and 28-day compressive strength using a ternary diagram of the cement, blast furnace slag, and fly ash proportions. Comparing specimens at the same testing age allows the relationship between binder composition and strength to be examined without differences in specimen age affecting the comparison.

The figure shows that some mixtures with higher cement proportions achieve relatively high compressive strength. However, high strength is also observed in mixtures containing slag or fly ash, which suggests that partially replacing cement with these materials does not necessarily result in lower strength. Considerable variation in strength is observed even among mixtures with similar binder proportions. This indicates that binder composition alone cannot fully explain the differences in strength. Other factors, such as water content, total binder content, and chemical admixtures, may also contribute to the observed variation. Therefore, multiple mixture characteristics should be considered when developing predictive models for concrete compressive strength.

#figure(
  image("figures/eda/fig3_ternary_binder.png", width: 100%),
  caption: [Binder composition and 28-day compressive strength.],
) <fig:ternary>

@fig:wb shows the relationship between the water-to-binder ratio (w/b), defined as the mass of water divided by the combined mass of cement, slag, and fly ash, and the compressive strength, with specimen age represented by color. A clear decreasing trend can be observed, as mixtures with lower w/b typically achieve higher strengths. For example, specimens with w/b below approximately 0.35 exhibit strengths ranging from about 20 to over 80 MPa, while most specimens with w/b above 0.70 have strengths below 30 MPa. This pattern is consistent with the understanding that excessive water relative to binder content increases porosity and reduces concrete strength.

However, differences still exist among specimens with similar w/b. The color distribution indicates that specimens tested at later ages generally achieve higher strength than specimens tested at earlier ages with comparable w/b. This indicates that both specimen age and w/b are associated with compressive strength, and other mixture characteristics may also explain some of the remaining variation. Therefore, the relationship should be interpreted as an association rather than as evidence of a causal effect from this dataset alone.

#figure(
  image("figures/eda/fig4_wb_joint.png", width: 100%),
  caption: [Compressive strength versus water-to-binder ratio by specimen age.],
) <fig:wb>

@fig:development provides a more detailed analysis of strength development by tracking the change in strength over time for individual concrete mixtures. Unlike @fig:raincloud, @fig:development (a) compares measurements of the same mix design at multiple ages. The strength of most mixtures increases rapidly during the early curing period, and the rate of increase slows down later. Mixtures with lower w/b usually achieve higher compressive strengths.

@fig:development (b) provides a more detailed comparison by normalizing the strength of each mixture by its 28-day strength. The normalized strength increases from approximately 0.46 at 3 days to 0.63 at 7 days and 0.82 at 14 days. At approximately 90 days, the median reaches 1.25, which indicates that the typical strength is about 25% higher than the corresponding 28-day value among the mixtures tested at that age. After about 90 days, the normalized strength changes little. However, the shaded percentile ranges show variation in strength development across mixtures. Therefore, while the general trend shows increasing strength with age, the rate of development varies among mixture designs.

#figure(
  image("figures/eda/fig5_strength_development.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Strength development of individual concrete mixtures.],
) <fig:development>

Several characteristics of the records are also important for modeling. Although the dataset has no missing values, 25 records are exact duplicates of other records. In addition, the 1,030 records come from only 428 unique mixtures, because 182 of these mixtures were tested at two or more ages, with up to eight ages per mixture. Records of the same mixture share all seven ingredient amounts, so they are not independent observations. Finally, as shown in @fig:corner, the ingredient amounts are correlated with each other, and in a linear model their variance inflation factors reach 8.0 (@sec:mlr).

Based on the exploratory data analysis, the compressive strength of concrete depends on multiple factors rather than on any single mix design characteristic. Specimen age and cement content are positively associated with strength, while water content and w/b are negatively associated with it. These findings shaped the predictive modeling in @sec:modeling in three ways. First, the nonlinear age effect and the w/b relationship motivated the feature transformations tested for linear regression (@sec:mlr) and the use of nonlinear models. Second, the correlations among the ingredients motivated the ridge penalty (@sec:ridge) and caution when interpreting coefficients and feature importance. Third, the repeated measurements of the same mixtures required a validation design in which each mixture appears in only one data subset (@sec:design).

= *Predictive Modeling* <sec:modeling>

Building on the exploratory analysis, four models were compared for predicting compressive strength: multiple linear regression (MLR), polynomial regression with ridge regularization, a regression tree, and random forest (RF). These models range from a simple linear baseline to a flexible ensemble of trees, which allows the hypotheses stated in @sec:intro to be tested. All models used the seven mixture ingredients and age as inputs, and all were evaluated on mixtures that were absent from the training data. MLR and polynomial ridge regression were implemented in Python, and the regression tree and RF were implemented in Julia. The predictions of RF were further interpreted with SHapley Additive exPlanations (SHAP) @lundberg2017.

== *Validation Design* <sec:design>

Before modeling, the 1,030 records were checked for repeated entries. Twenty-five records were exact copies of another record in all nine variables and were removed, leaving 1,005 records from 428 unique mixtures. Nine combinations of mixture and age contain two records with different strength values. These records were kept because they represent separate test results rather than repeated entries.

The cleaned records were then divided into training and test sets by mixture. Whole mixtures were assigned to the test set in random order until 20% of the records were reached (random seed 492). The training set contains 804 records from 341 mixtures, and the test set contains 201 records from 87 mixtures, with no mixture appearing in both sets. The training mixtures were further assigned to five validation folds of 160 or 161 records each, again keeping each mixture within a single fold. The strength distributions of the two sets are similar (mean of 35.4 MPa for training and 34.9 MPa for testing; two-sample Kolmogorov–Smirnov test, p = 0.94). The assignment of every record is stored in `data/concrete_split.csv`, and the same file was used for all four models.

The three tunable models were each evaluated with 20 predefined hyperparameter configurations, so that they received the same number of candidate evaluations. For polynomial ridge regression, the configurations were 20 penalty values spaced evenly on a logarithmic scale from 0.0001 to 10,000. For the regression tree, they combined maximum depths of 3, 5, 8, 12, or no limit with minimum leaf sizes of 2, 5, 10, or 20 observations. For RF, they combined maximum depths of 10 or no limit, minimum leaf sizes of 2 or 5 observations, and 2, 3, 4, 6, or 8 candidate predictors per split, with the number of trees fixed at 500. MLR has no comparable tuning parameter, so several feature sets were compared instead (@sec:mlr).

Each configuration was evaluated on the same five validation folds, and the configuration with the lowest mean root mean squared error (RMSE) across the folds was selected. For the regression models, the inputs were standardized using the means and standard deviations of the training part of each fold, and polynomial terms were standardized after expansion. The tree-based models used unscaled inputs because their split rules do not depend on the scale of the inputs. After selection, each model was refitted to the full training set and evaluated once on the test set. The test RMSE, the mean absolute error (MAE), and the coefficient of determination ($R^2$) are reported, with RMSE and MAE expressed in MPa. Ordinary random cross-validation (CV), which ignores the mixture groups, was used only as a supplementary diagnostic, and the test results were not used for any further tuning.

== *Multiple Linear Regression* <sec:mlr>

MLR was fitted by ordinary least squares. The baseline model used the eight source predictors. The inputs were standardized with the means and standard deviations of each training fold, so each coefficient represents the change in predicted strength (MPa) for an increase of one standard deviation in that predictor.

The exploratory analysis suggested two relationships that a linear model cannot represent with the source predictors alone. First, strength increases with age in a monotonic but nonlinear way (@fig:raincloud, @fig:development), so a straight-line age term is expected to fit poorly. Second, strength decreases with w/b (@fig:wb), which is a ratio of four inputs rather than a linear combination of them. Therefore, four alternative feature sets were compared with the baseline: (1) age replaced by its natural logarithm, ln(age); (2) ln(age) together with w/b; (3) the second set without the two aggregate variables, as a test of feature selection; and (4) the second set with ln(strength) as the response, with predictions transformed back to MPa. All feature sets were evaluated on the same five validation folds, and the set with the lowest mean validation RMSE was selected. The test set was used only once, after this selection.

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
  caption: [Performance of multiple linear regression feature sets (p: number of predictors; RMSE and MAE in MPa; validation values are mean ± standard deviation over five folds).],
) <tab:mlr>

@fig:mlr-features (b) compares the standardized coefficients of the baseline and selected models. The 95% confidence intervals are based on heteroscedasticity-robust (HC3) standard errors, because the spread of the residuals increases with predicted strength (Breusch–Pagan test, p < 0.001). In both models, cement, slag, and fly ash have positive coefficients, and cement has the largest effect among the ingredients. In the baseline model, an additional 1 kg/m#super[3] of cement is associated with 0.12 MPa higher strength, while an additional 1 kg/m#super[3] of water is associated with 0.11 MPa lower strength. In the selected model, ln(age) has the second-largest coefficient after cement (10.2 and 11.2 MPa per standard deviation, respectively) and the narrowest confidence interval. However, when w/b is included, the water coefficient is no longer significantly different from zero, because the effect of water is now shared with w/b. The variance inflation factors (VIF) also increase from a maximum of 8.0 in the baseline model to 24.5 for cement and 19.0 for w/b in the selected model. Therefore, the coefficients of the selected model should not be interpreted one at a time. The positive coefficients of the aggregates should also be interpreted with caution. Because the ingredient amounts together make up one cubic meter of concrete, these coefficients may reflect differences in the overall mixture design rather than a direct strengthening effect of the aggregates. This collinearity is one reason for the ridge penalty used in the polynomial model (@sec:ridge).

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

To check whether these results depend on the particular split, the baseline and selected models were refitted on 200 alternative mixture-grouped 80/20 splits. The selected model had a median test RMSE of 7.2 MPa (5th–95th percentile: 6.4–8.1 MPa), compared with 10.5 MPa (9.6–11.3 MPa) for the baseline, and it was more accurate in all 200 splits. The test RMSE of 6.8 MPa from the main split is therefore slightly better than typical. The baseline model was also evaluated with random CV. The result (10.46 MPa) was almost identical to the grouped result (10.53 MPa), which suggests that grouping has little effect for a linear model, because such a model cannot memorize individual recipes. More flexible models may behave differently, which is why the grouped split was kept for all models.

The selected MLR model reduces the error of the mean-only predictor by 57%, and 59% and 83% of the test predictions fall within ±5 MPa and ±10 MPa of the measured strength, respectively. However, an RMSE of 6.8 MPa is about 20% of the median 28-day strength in the dataset (34 MPa, @fig:raincloud), and the largest errors occur for high-strength mixtures and long curing ages. Therefore, the MLR model is useful for describing general trends and as a baseline for the other models, but it is not accurate enough to select a mixture that must meet a specific target strength. The diagnostics suggest that accuracy could be improved by an age term that levels off at long ages, by interaction terms between age and mixture composition, and by models that can represent nonlinear effects, which are examined in the following subsections. Reading guides for @fig:mlr-features and @fig:mlr-diagnostics are provided as text files with the same names in the `modeling/mlr/figures/` folder.

== *Polynomial Regression with Ridge Regularization* <sec:ridge>

Polynomial regression with ridge regularization was used to examine whether adding generic nonlinear terms, instead of the targeted transformations used for MLR, could improve strength prediction. The model started with the same eight predictors as the baseline MLR: cement, slag, fly ash, water, superplasticizer, coarse aggregate, fine aggregate, and specimen age. Squared terms and pairwise interactions were then added, which resulted in 44 predictors in total. The additional terms allow the model to represent curved relationships and interactions between mixture characteristics. However, they also introduce many correlated predictors, in addition to the correlations among the ingredients found in @sec:eda. Ridge regression @hoerl1970 was therefore used to limit large coefficients and reduce overfitting.

The ridge model was fitted by minimizing the squared prediction errors together with a penalty on the squared coefficients, and the intercept was not penalized. As described in @sec:design, 20 penalty values between 0.0001 and 10,000 were evaluated on the five validation folds. The polynomial terms were expanded and then standardized using the mean and standard deviation of each training fold, and the same scaling was applied to the corresponding validation fold. This prevented information from the validation data from being used during model fitting.

@fig:ridge-tuning (a) shows the mean validation RMSE for the 20 penalty values, while @fig:ridge-tuning (b) shows the RMSE for each fold at the selected penalty. The lowest mean validation RMSE was 8.42 ± 0.55 MPa at a penalty of λ = 11.29. After selecting this value, the polynomial expansion, scaling, and ridge model were fitted again using all 804 training observations. The final model was then evaluated on the 201 test observations, which were not used for parameter selection.

#figure(
  image("modeling/ridge/figures/ridge_tuning.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Ridge penalty selection. (a) Mean validation RMSE across 20 penalty values, with the shaded range showing one standard deviation across the five grouped folds. (b) Validation RMSE for each fold at the selected penalty.],
) <fig:ridge-tuning>

The polynomial ridge model achieved a test RMSE of 7.62 MPa, an MAE of 5.88 MPa, and an $R^2$ of 0.765. Compared with the baseline MLR using the eight source predictors (RMSE of 10.39 MPa), polynomial ridge regression reduced the test RMSE by approximately 27%. However, it did not perform as well as the selected MLR using ln(age) and w/b (RMSE of 6.77 MPa). This suggests that simply adding quadratic and interaction terms was less effective than the targeted transformations identified in the exploratory analysis. Because the model uses many related polynomial terms, its individual coefficients should not be interpreted as separate physical effects.

@fig:ridge-diagnostics shows the model predictions and residuals on the test set. In @fig:ridge-diagnostics (a), most predicted strengths follow the observed values, although noticeable errors remain. About 53% of the predictions are within ±5 MPa, and 79% are within ±10 MPa. The residuals in @fig:ridge-diagnostics (b) also vary across specimen ages. For the 14 test specimens aged 180 days or more, the RMSE increased to 10.63 MPa, with a mean residual of −2.93 MPa, which indicates that the model tended to overpredict the strength of these older specimens. For the 14 specimens with measured strength above 60 MPa, the RMSE was 11.13 MPa and the mean residual was +3.67 MPa, which indicates that the model tended to underpredict high strengths. These groups contain relatively few observations, so their error estimates should be interpreted with caution.

#figure(
  image("modeling/ridge/figures/ridge_diagnostics.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Test-set diagnostics for polynomial regression with ridge regularization. (a) Predicted versus observed strength. (b) Residuals by specimen age. (c) Residuals versus predicted strength.],
) <fig:ridge-diagnostics>

Overall, polynomial ridge regression improves the prediction compared with the baseline linear model and captures some nonlinear relationships among the ingredients and age. However, its errors are still large for some older and high-strength specimens. Therefore, it may be useful for preliminary comparisons of mixtures within the range represented by the dataset, but it is not accurate enough to confirm that a mixture meets a required design strength without laboratory testing. Among the two parametric regression approaches, the selected MLR has the lower test error. The next two subsections examine tree-based models, which can represent nonlinear relationships without specifying the form of these relationships in advance. Reading guides for @fig:ridge-tuning and @fig:ridge-diagnostics are provided as text files with the same names in the `modeling/ridge/figures/` folder.

== *Regression Tree* <sec:tree>

The regression tree model was built using the DecisionTree.jl package in Julia. A regression tree recursively partitions the observations based on the values of the input variables, so that the compressive strengths within each resulting group are as similar as possible @breiman2017cart. Each terminal (leaf) node predicts the average strength of the training observations that it contains.

To control the complexity of the model, two hyperparameters were tuned: the maximum tree depth and the minimum number of observations per leaf node. The maximum depth limits the number of successive splits, while the minimum leaf size sets the smallest number of observations allowed in a terminal node. A larger maximum depth and a smaller leaf size allow the tree to capture more complex relationships but may lead to overfitting. Five values were considered for the maximum depth (3, 5, 8, 12, and unlimited) and four values for the minimum leaf size (2, 5, 10, and 20), which gives 20 combinations. Each combination was evaluated with five-fold cross-validation on the training set, and the combination with the lowest mean validation RMSE was selected for the final model.

#figure(
  image("modeling/rt/rt_rmse_heatmap.png", width: 100%),
  caption: [Mean validation RMSE across 20 regression tree hyperparameter combinations using five-fold cross-validation.],
) <fig:rtree-rmse>

As shown in @fig:rtree-rmse, the mean validation RMSE generally decreased as the maximum depth increased from 3 to 12, which indicates that deeper trees represent the complex relationships in the data more effectively. A smaller minimum leaf size also helped to lower the error, especially for deeper trees. However, increasing the maximum depth beyond 12 did not improve the results further. Among the 20 combinations, a maximum depth of 12 and a minimum leaf size of 2 had the lowest mean validation RMSE of 8.7 MPa, compared with about 11.6 MPa for the shallowest trees, a reduction of about 25%. The final regression tree was trained on the full training set with this combination and then evaluated on the test set, where it achieved an RMSE of 6.76 MPa, an MAE of 4.92 MPa, and an $R^2$ of 0.815 (@tab:all-comparison). Thus, the final tree can fit about 81.5% of the variance in the measured strengths of the test specimens. The test RMSE is noticeably lower than the mean validation RMSE, and this difference is discussed in @sec:comparison.

#figure(
  image("modeling/rt/rt_predOb.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Regression tree performance on the test set: observed versus predicted compressive strength (left), residuals versus specimen age (middle), and residuals versus predicted compressive strength (right).],
) <fig:rtree-performance>

The left panel of @fig:rtree-performance shows that most predicted strengths lie near the 1:1 line, and most fall within the ±10 MPa band. However, some predictions differ substantially from the observed values, which indicates lower accuracy for certain mixture designs. The predictions also form horizontal bands, because each leaf of a single tree predicts one constant value. In the middle panel, the residuals at each age are distributed on both sides of zero, so the model does not consistently overestimate or underestimate strength at any single age. However, the locally weighted scatterplot smoothing (LOWESS) trend decreases slowly with age, which indicates a change from slight underestimation at early ages to slight overestimation at long ages. Similarly, the right panel shows that the residuals are concentrated near zero for low and medium predicted strengths, while the LOWESS trend slopes downward for predictions above about 50 MPa. This suggests that the model tends to overestimate strength when it predicts high values.

To assess the relative importance of the eight inputs, each input was randomly permuted 30 times while the other inputs were kept unchanged. The resulting change in the training RMSE relative to the unpermuted model was recorded in @fig:rt-feature-importance. Cement content has the highest importance, with a mean increase in RMSE of about 14 MPa, followed by specimen age (12.7 MPa), water content (9.5 MPa), and slag content (7.8 MPa). The importance of the remaining four inputs (fine aggregate, fly ash, coarse aggregate, and superplasticizer) is much smaller, between about 2 and 3 MPa, and the short error bars indicate that the estimates vary little between permutations. These results suggest that the regression tree relies mainly on cement, age, water, and slag. However, permutation importance measures how much the model depends on each input, not the actual physical effect of the input on concrete strength. Because the importance was computed on the training data, it may also partly reflect patterns that the deep tree memorized.

#figure(
  image("modeling/rt/rt_feature_importance.png", width: 100%),
  caption: [Permutation feature importance of the regression tree model. Points represent the mean change in training RMSE across 30 random permutations.],
) <fig:rt-feature-importance>

Overall, the tuned regression tree predicted the test specimens with an accuracy similar to that of the selected MLR. However, its MAE of 4.92 MPa is still large relative to typical strength values, and the residual analysis shows a slight tendency to overestimate strength at long curing ages and at high predicted strengths. In addition, a single tree produces piecewise-constant predictions, which limits its ability to represent gradual changes in strength as the inputs change. This limitation motivates the RF model in the next subsection, which averages the predictions of many trees.

== *Random Forest and SHAP Analysis* <sec:rf>

RF regression was used to model nonlinear relationships among the seven concrete ingredients, specimen age, and compressive strength @breiman2001. The model was implemented in Julia with DecisionTree.jl and used the eight original predictors without scaling or additional feature transformations. To maintain comparability, the same 804 training observations, 201 test observations, and five mixture-grouped validation folds were taken directly from `data/concrete_split.csv`. Each of the 20 predefined hyperparameter combinations described in @sec:design was evaluated with 500 trees. Hyperparameters were selected solely by the lowest mean RMSE across the five mixture-grouped validation folds, and random CV was computed separately as a diagnostic that did not influence model selection.

@fig:rf-tuning compares these two validation strategies. The minimum grouped validation RMSE was 6.34 ± 0.89 MPa (mean ± standard deviation across folds), obtained with unrestricted maximum depth, a minimum leaf size of two, and four candidate predictors per split. For this configuration, random CV yielded 5.65 ± 0.74 MPa. Random folds may place observations from the same mixture in both the training and validation subsets, which produces an easier prediction task. Thus, the lower random-CV error is consistent with information overlap between the subsets, although the magnitude of this difference does not, by itself, establish its cause. In contrast to MLR, for which random and grouped CV gave almost the same error (@sec:mlr), the more flexible RF appears to benefit from seeing other ages of the same recipe. Grouped CV better reflects the objective of predicting the strength of previously unseen mixtures and was therefore the sole basis for hyperparameter selection.

#figure(
  image("figures/rf/fig_rf_tuning.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Random forest hyperparameter evaluation. (a) Mean RMSE ± one standard deviation across the five mixture-grouped validation folds, used for model selection. (b) Ordinary random five-fold cross-validation, shown as a supplementary diagnostic only. Each configuration contains 500 trees; the star identifies the configuration selected from panel (a).],
) <fig:rf-tuning>

The selected RF model was refitted using all 804 training observations and evaluated once on the 201 test observations. It achieved an RMSE of 5.23 MPa, an MAE of 3.91 MPa, and an $R^2$ of 0.889 (@tab:all-comparison). Its test RMSE was approximately 23% lower than that of the selected MLR model (6.77 MPa) and approximately 31% lower than that of polynomial ridge regression (7.62 MPa). The lower test error supports the usefulness of flexible nonlinear predictions for this dataset, although the feature sets differ between the selected MLR and RF models and the comparison reflects only this particular test split.

@fig:rf-diagnostics summarizes the RF test predictions and residuals. The predictions generally track the measured strengths, with an overall mean residual (observed minus predicted) of +0.46 MPa. However, for the 14 specimens with measured strengths above 60 MPa, the RMSE reached 10.07 MPa, nearly twice the overall test RMSE, and their mean residual was +7.18 MPa, which indicates a tendency to underpredict high strengths. For the 14 specimens tested at ages of at least 180 days, the RMSE was 4.91 MPa and the mean residual was +0.64 MPa, which is a much smaller long-age bias than that of the selected MLR model. These subgroup estimates are based on only 14 observations each and require confirmation with additional independent data. Despite its improved overall accuracy, the RF model cannot replace laboratory strength testing when compliance with a specified design strength must be established.

#figure(
  image("figures/rf/fig_rf_test_diagnostics.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Random forest performance on the test set (n = 201). (a) Predicted versus observed compressive strength, with the 1:1 line and a ±10 MPa band. (b) Observed-minus-predicted residuals by specimen age, with medians. (c) Residuals versus predicted strength, with dashed lines at ±10 MPa.],
) <fig:rf-diagnostics>

To interpret the fitted RF model, approximate SHAP values were calculated in Julia using ShapML.jl @lundberg2017. A random sample of 100 training observations provided the reference distribution, with a reference prediction of 36.32 MPa. Stochastic Shapley estimates were calculated for all 201 test observations using 60 samples per feature. The maximum absolute difference between an RF prediction and the reference prediction plus its estimated SHAP contributions was 0.40 MPa across the test set. Thus, the attributions offer an approximate, rather than exact, additive reconstruction of the predictions of the fitted model. Mean absolute SHAP values were used to summarize global importance. The leading predictors were age (31.7% of the summed mean absolute SHAP importance), cement (27.0%), and water (14.0%), followed by superplasticizer (8.7%) and slag (7.9%) (@fig:rf-importance). These percentages represent relative contributions to the predictions of the fitted model, rather than proportions of explained variance or physical causal effects.

#figure(
  image("figures/rf/fig_rf_shap_importance.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Global random forest feature importance based on mean absolute approximate SHAP values across the 201 test observations. Values are normalized to sum to 100%.],
) <fig:rf-importance>

The SHAP summary (@fig:rf-summary) and dependence plots (@fig:rf-dependence) provide information about the direction and nonlinearity of these associations. Larger ages and cement contents generally contributed positively to predicted strength, whereas greater water content generally contributed negatively. Age contributions increased markedly at early curing ages and changed less at later ages, which is consistent with the nonlinear strength development observed in @fig:development. Positive SHAP contributions were also associated with greater slag content in portions of the observed data. However, dependence patterns need not be monotonic for every observation, and the apparent predictor effects may partly reflect correlations and interactions among the ingredients. Because ShapML.jl produces sampling-based approximations with a finite reference sample, these SHAP values should be interpreted as estimates of the behavior of the model, not as exact or causal decompositions of concrete strength.

#figure(
  image("figures/rf/fig_rf_shap_summary.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Approximate SHAP summary for the 201 test observations. Each point represents one observation. The horizontal position gives its contribution to predicted compressive strength (MPa); blue indicates lower predictor values, and pink indicates higher predictor values. Positive contributions increase the prediction relative to the reference value.],
) <fig:rf-summary>

#figure(
  image("figures/rf/fig_rf_shap_dependence.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [SHAP dependence plots for (a) specimen age, (b) cement, (c) water, and (d) slag. Vertical coordinates are estimated contributions to predicted strength (MPa); colors indicate the corresponding secondary predictor shown by each color scale.],
) <fig:rf-dependence>

Overall, RF outperformed the other models on the shared test set and captured important nonlinear associations. Nonetheless, the systematic underprediction of strengths above 60 MPa and the observational nature of the dataset limit its use for strength-based acceptance decisions. Validation on independent concrete mixture datasets, particularly with broader coverage of high-strength specimens, would be required before practical use. The RF and SHAP figures are provided in the `figures/rf/` folder.

== *Comparison of Models* <sec:comparison>

@tab:all-comparison and @fig:comparison compare the four models on the same validation folds and test set. RF achieved the lowest error in both validation (6.34 ± 0.89 MPa) and testing (RMSE of 5.23 MPa, MAE of 3.91 MPa, and $R^2$ of 0.889). Compared with the selected MLR model and the regression tree, RF reduced the test RMSE by about 23% in both cases. On the test set, the regression tree and the selected MLR performed almost equally (RMSE of 6.76 and 6.77 MPa), and polynomial ridge regression had the largest error among the four models (7.62 MPa).

#figure({
  set text(hyphenate: false)
  set par(justify: false)
  table(
    columns: (2.6fr, 1.5fr, 0.9fr, 0.9fr, 0.9fr),
    inset: 3pt,
    align: (left, center, center, center, center),

    table.header(
      [*Model*],
      [*Validation RMSE*],
      [*Test RMSE*],
      [*Test MAE*],
      [*Test $R^2$*],
    ),

    [Mean-only predictor], [–], [15.72], [12.80], [−0.001],
    [MLR, 8 source predictors], [10.53 ± 0.72], [10.39], [8.10], [0.563],
    [MLR, ln(age) + w/b], [7.39 ± 0.50], [6.77], [5.25], [0.815],
    [Polynomial ridge], [8.42 ± 0.55], [7.62], [5.88], [0.765],
    [Regression tree], [8.70], [6.76], [4.92], [0.815],
    [*Random forest*], [*6.34 ± 0.89*], [*5.23*], [*3.91*], [*0.889*],
  )},
  caption: [Comparison of the predictive models on the same validation folds and test set (n = 201). RMSE and MAE are expressed in MPa; validation values are mean ± standard deviation over five folds (not reported for the regression tree).],
) <tab:all-comparison>

#figure(
  image("modeling/comparison/figures/model_comparison.png", width: 100%),
  caption: [Validation and test RMSE of all models. Circles with bars show the mean ± standard deviation over the five validation folds; diamonds show the test RMSE.],
) <fig:comparison>

The two evaluation sets do not rank the other three models in the same order. In validation, the regression tree had the largest error (8.70 MPa), and its test RMSE was 1.94 MPa lower than its validation RMSE, which is the largest gap among the four models. In fact, all four models performed better on the test set than in validation, by 0.63 MPa for MLR, 0.80 MPa for polynomial ridge regression, 1.94 MPa for the regression tree, and 1.11 MPa for RF. The repeated-split analysis in @sec:mlr showed that the main test split is slightly easier than a typical split, so the test results are probably somewhat optimistic for all models, and the validation RMSE gives a more conservative estimate of the error for new mixtures. Both evaluation sets agree that RF is the most accurate model, while the order of the other three models depends on which set is used.

The four models describe the relationships among mixture proportions, curing age, and compressive strength in different ways. MLR provides a simple and interpretable framework, and its performance improved substantially after age was log-transformed and w/b was added, as suggested by the exploratory analysis. Polynomial ridge regression expanded the eight predictors into 44 polynomial features and controlled their coefficients with an L2 penalty. Although this model is more flexible, it did not outperform the selected MLR, which shows that adding generic polynomial terms does not necessarily improve prediction. The regression tree captures nonlinear relationships through recursive splitting and provides an understandable set of decision rules, and RF further improves predictive performance by averaging many trees, which reduces its dependence on the structure of any single tree.

Both the permutation importance of the regression tree and the SHAP analysis of RF identified age, cement, and water as three of the four most influential predictors. However, slag ranked fourth for the regression tree, while superplasticizer ranked fourth for RF. Because permutation importance measures changes in prediction error while SHAP measures contributions to the predictions, the values of the two methods cannot be compared directly. Nevertheless, the agreement on the leading predictors indicates that both tree-based models rely on similar key inputs, which are also the variables most strongly associated with strength in the exploratory analysis (@fig:corner).

= *Discussion* <sec:discussion>

This project asked how accurately the compressive strength of previously unseen concrete mixtures can be predicted from their mixture proportions and age. The results support both hypotheses stated in @sec:intro. First, transforming age to ln(age), which was motivated by the nonlinear strength development observed in @fig:development, reduced the validation RMSE of MLR by 29%, much more than any other change to the linear model (@tab:mlr). Second, the most flexible model, RF, predicted unseen mixtures more accurately than all other models in both validation and testing (@tab:all-comparison). However, flexibility alone was not sufficient: polynomial ridge regression with 44 generic terms was less accurate than MLR with two targeted transformations, and a single regression tree had the highest validation error of the four models. These results indicate that features based on knowledge of concrete strength development can provide a large part of the improvement offered by flexible models, and that averaging many trees was needed to obtain stable nonlinear predictions.

Whether the best model is accurate enough to be useful depends on how it would be used. The test RMSE of RF (5.2 MPa) is one third of that of a predictor that always returns the mean strength (15.7 MPa), and it corresponds to about 15% of the median 28-day strength in the dataset (34 MPa). Because the validation RMSE was higher (6.3 MPa) and the test split appears to be slightly easier than average (@sec:comparison), errors of about 5 to 6 MPa should be expected for new mixtures within the range of this dataset. Errors of this size are acceptable for ranking candidate mixtures and deciding which trial batches to cast. However, they are too large to confirm that a mixture meets a specified design strength, especially for high-strength concrete: for the 14 test specimens stronger than 60 MPa, RF underpredicted strength by 7.2 MPa on average, with an RMSE of 10.1 MPa. Therefore, the models can support preliminary mixture assessment, but they cannot replace laboratory strength testing.

Several characteristics of the data limit the achievable accuracy. The dataset does not record the cement type, the aggregate properties, or the curing conditions (@sec:dataset), so differences caused by these factors appear as unexplained error. High-strength specimens and long curing ages are poorly represented in the data, and these are the conditions under which all models showed their largest errors (@sec:mlr, @sec:ridge, @sec:rf). The test set contains only 87 mixtures, and the test RMSE of MLR varied from 6.4 to 8.1 MPa (5th–95th percentile) across 200 alternative splits (@sec:mlr). Therefore, differences of less than about 1 MPa between models, such as those among MLR, polynomial ridge regression, and the regression tree, may not be meaningful. Finally, the dataset is observational, so the coefficients, permutation importance, and SHAP values describe associations learned by the models rather than causal effects of the ingredients.

If this work were continued, several next steps would be valuable. First, the models should be validated on independent datasets from other laboratories and countries @chou2014, to test whether the accuracy found here holds outside the conditions of this dataset. Second, the evaluation of all four models should be repeated over many grouped splits or with nested cross-validation, as was done for MLR, so that the differences between models can be tested statistically. Third, features that represent strength development more realistically, such as an age function that levels off after about 90 days and interactions between age and the binder composition, could reduce the remaining systematic errors at long ages. Fourth, other ensemble methods, such as boosting @feng2020, could be compared with RF. Fifth, prediction intervals rather than single predictions would allow an engineer to judge whether a candidate mixture is likely to reach a target strength with a chosen level of confidence. Finally, additional data on high-strength mixtures, cement type, aggregate properties, and curing conditions would address the largest sources of error identified in this project.
