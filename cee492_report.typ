
#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Prediction of Concrete Compressive Strength Using Concrete Mixture Characteristics],
  abstract: [
    This project aims to investigate the relationships between concrete mixture characteristics, age, and compressive strength using exploratory data analysis and predictive modeling. Multiple statistical and machine-learning approaches will be evaluated to estimate concrete compressive strength and identify influential mixture characteristics. The findings are expected to provide insights into concrete strength development and inform future mixture design adjustments.
  ],
  authors: (
    (
      name: "Mohamed Alsaleh",
      department: [Civil Engineering Department],
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

= *Proposed Analysis*

The objective of this project is to investigate the relationships between concrete mixture characteristics, age, and compressive strength and to develop predictive models for concrete compressive strength. The first stage of the analysis will consist of exploratory data analysis to examine the distributions of the variables and identify relationships between the mixture components, age, and compressive strength. Appropriate graphical and statistical methods will be used to explore these relationships, while feature importance analysis will help identify the mixture characteristics most strongly associated with concrete compressive strength.

The second stage of the project will use multiple predictive modeling approaches introduced in the course. These may include statistical regression methods and machine-learning models, as appropriate based on the methods covered during the semester. The models will be developed using the eight input variables and evaluated using appropriate prediction-performance measures. Their predictive capabilities will then be compared to determine how different statistical and machine-learning approaches perform for estimating concrete compressive strength. This analysis is useful because compressive strength is an important indicator of concrete performance, while strength development depends on several interacting mixture characteristics and the age of the concrete. Comparing multiple predictive approaches can also provide insight into whether more flexible machine-learning methods offer improved prediction compared with conventional statistical regression models. Furthermore, identifying the most influential mixture characteristics can provide insights into the factors associated with concrete strength and help guide future mixture design adjustments to improve concrete performance.
