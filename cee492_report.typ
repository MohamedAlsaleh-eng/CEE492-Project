
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
  bibliography: bibliography("refs.bib"),
)

= *Dataset Description*

== *Dataset Source and Overview*

This project will use the Concrete Compressive Strength dataset available through the UCI Machine Learning Repository @yeh1998dataset. The dataset was originally provided by Prof. I-Cheng Yeh of Chung-Hua University. The data were developed from laboratory measurements of concrete mixtures, where the actual compressive strength of each mixture was determined at a specified age. The dataset is provided in raw, unscaled form and is available as an Excel file (Concrete_Data.xls).

Dataset source: #link("https://archive.ics.uci.edu/dataset/165/concrete+compressive+strength")[UCI Machine Learning Repository, _Concrete Compressive Strength_ dataset]

DOI: #link("https://doi.org/10.24432/C5PK67")[10.24432/C5PK67]

The dataset contains 1,030 observations and nine quantitative variables. Eight variables describe the concrete mixture composition and age and are used as input variables. The ninth variable, concrete compressive strength, is the output variable. The dataset contains no missing values.

== *Dataset Variables*

The variables included in the dataset are summarized in Table @tab:variables.

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

Therefore, the primary response variable for this project will be *concrete compressive strength in MPa*, while the remaining eight variables will be considered potential predictors.

== *Exploratory Data Analysis*

[please add description]

[A reading guide and explanation for each figure is provided as a text file with the same name in the `figures/eda/` folder of the project repository.]

@fig:raincloud shows the distribution of compressive strength of concrete in different ages. Overall, the median value of compressive strength increases with age, especially during the early stage.The median compressive strength increased from around 16 MPa at 3 days to 34 MPa at 28 days, and continue to increase to 52 MPa at 56 days. However, the compressive strength varies within each age group. This variability suggests that curing age is not sufficient to be the only variable to explain concrete strength. 

In addition, the strength distributions across the different age groups do not necessarily show a consistent upward trend.This does not always indicate the concrete loses strength over time, as the mix designs used for specimens at different ages may vary.The sample sizes are not consistent either: 425 specimens were tested at 28 days, while only 22 were tested at 91 days. Therefore, comparisons between different ages may not be entirely valid, and predictive models should consider this uneven distribution of specimen ages.

#figure(
  image("figures/eda/fig1_raincloud_age.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Distribution of compressive strength by specimen age.],
) <fig:raincloud>

@fig:corner shows the pairwise relationships and Spearman’s rank correlation coefficients among the selected variables. The age of the test specimens showed the strongest positive correlation with compressive strength (ρ=0.60), followed by cement content (ρ=0.48) and high-performance water-reducing agent content (ρ=0.35). Water content showed a negative correlation with strength (ρ=-0.31). 

Meanwhile, these relationships are not necessarily linear. For example, the relationship between age and strength is described more accurately by the Spearman correlation coefficient (ρ = 0.60) than by the Pearson correlation coefficient (r = 0.33), indicating a monotonically increasing but nonlinear relationship.

#figure(
  image("figures/eda/fig2_corner.png", width: 100%),
  placement: auto,
  scope: "parent",
  caption: [Pairwise relationships and Spearman rank correlations among mixture variables, age, and compressive strength.],
) <fig:corner>

@fig:ternary uses a ternary diagram to determine the relationship between binder proportions and 28-day compressive strength. Some mixtures with higher cement content achieved relatively higher strength, while those containing admixtures exhibited more variability. However, high compressive strength is not limited to cement-dominated mixtures. Replacing part of the cement with blast furnace slag or fly ash does not necessarily result in reduced strength, the outcome may depend on proportions and other mixture characteristics.

#figure(
  image("figures/eda/fig3_ternary_binder.png", width: 100%),
  caption: [Binder composition and 28-day compressive strength.],
) <fig:ternary>

@fig:wb illustrates the relationship between the water-cement ratio and the compressive strength of concrete, the age of the test specimens are indicated by color. A clear negative correlation can be observed as mixtures with lower water-cement ratios typically achieve higher compressive strengths. This relationship is consistent with the role of water in cement-based materials. Although water is essential for cement hydration, excessive amount of water can lead to increasing porosity of the hardened material, which may reduce compressive strength. 

However, differences still exist among specimens with similar water-to-binder ratios. The color distribution indicates that specimens tested at later ages generally show higher strength than those tested at earlier ages with comparable water-to-cement ratios. 

#figure(
  image("figures/eda/fig4_wb_joint.png", width: 100%),
  caption: [Compressive strength versus water-to-binder ratio by specimen age.],
) <fig:wb>

@fig:development provides a more detailed analysis of strength development by tracking the change in strength over time for different concrete mixtures.Unlike @fig:raincloud, @fig:development examines measurement data for the same mix design at multiple ages.
The strength of most mixtures increases rapidly during the early curing period, and the rate slows down later. Mixtures with lower water-to-cement ratios usually can achieve higher compressive strengths.

@fig:development (b) further quantifies the relationship by normalizing the strength of each mixture relative to 28-day strength.The median strength rise from ~0.46 at day 3 to 0.63 at day 7, and further to 0.82 at day 14. By day 56, the median reached 1.15, continue increasing to 1.25 between days 90 and 100. 
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