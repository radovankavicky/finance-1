##---- Portfolio Allocation

# max portfolio expectation given constraints
portfolioAllocation <- function() {

    ## ExpectedReturns:
    ## | Growth (x1) | Value (x2) | Bond (x3) | MM (x4) |
    ## |-------------+------------+-----------+---------|
    ## |         25% |       5.5% |      3.3% |    2.5% |

    ## Constraints:
    ## 1) Max Investment for each Asset Class: 30% of Initial
    ## 2) 2*x1 + 3*x3 < 30% of Initial
    ## 3) x1 + 2*x2 + 3*x3 + 4*x4 < 2 * Initial
    ## 4) x1, x2, x3, x4 >= 0 and sums to 1

    library(lpSolve)
    library(lpSolveAPI)

    initial <- 10e6
    model <- make.lp(0, 4)
    set.objfn(model, -1*c(.25, .055, .033, .025))

    add.constraint(model, c(1, 0, 1, 0), "<=", .5*initial)
    add.constraint(model, c(4, 2, 2, 1), "<=", 2* initial)
    add.constraint(model, c(1,0, 0, 0), "<=", .4*initial)
    add.constraint(model, c(0, 1, 0, 0), "<=", .4*initial)
    add.constraint(model, c(0,0, 1, 0), "<=", .4*initial)
    add.constraint(model, c(0,0, 0, 1), "<=", .4*initial)
    add.constraint(model, c(1, 1, 1, 1), "=", initial)

    set.bounds(model, lower=c(0, 0, 0, 0))
    solve(model)
    max.val <- -get.objective(model)
    weights <- get.variables(model)

    cat("\nMax Objective Value:", as.integer(max.val))
    cat("\nx1:", as.integer(weights[1]))
    cat("\nx2:", as.integer(weights[2]))
    cat("\nx3:", as.integer(weights[3]))
    cat("\nx4:", as.integer(weights[4]))
    cat("\n\n")
}
portfolioAllocation()

# 2nd method of maximizing expectation
portfolioAllocation2ndMethod <- function () {

    library(lpSolve)

    initial <- 10e6
    constraints <- rbind(c(1, 0, 1, 0),
                         c(4, 2, 2, 1),
                         c(1, 0, 0, 0),
                         c(0, 1, 0, 0),
                         c(0, 0, 1, 0),
                         c(0, 0, 0, 1),
                         c(1, 1, 1, 1))
    lp <- lp(objective.in=-1*c(.25, .055, .033, .025),
             const.mat=constraints,
             const.rhs=initial*c(.5, 2, .4, .4, .4, .4, 1),
             const.dir=c(rep("<=", 6), "="))

    cat("\nMax Objective Value:", as.integer(-lp$objval))
    for(i in 1:4) {
        cat("\nx", i, ":", as.integer(lp$solution[i]))
    }
    cat("\n\n")

}
portfolioAllocation2ndMethod()

# Quadratic Programming, maximizing expected return and minimizing risk
portfolioRisk <- function() {
    ## invest in 3 stocks with expected returns .03, .05, .06
    ## constraints that the weights add up to 1
    ## and cov:
    ## [.01, .02, .02]
    ## [.02, .01, .02]
    ## [.02, .02, .01]
    ## k = 2
    ## max t(x)*beta - k/2 * t(beta) * Cov * beta

    library(quadprog)
    A <- rbind(rep(1, 3), diag(3))
    A <- t(A)

    x <- c(.005, .0075, .02)
    b <- c(1, 0, 0, 0)
    Cov <- matrix(c(0.01, 0.003, 0.003, 0.003, 0.01, 0.003, 0.003, 0.003, 0.01), nrow=3)

    result <- solve.QP(2 * Cov, x, A, b, meq=1)
    cat("\nMax Objective Value:", -result$value)
    for(i in 1 : 3) {
        cat("\nx", i, ":", result$solution[i])
    }
    cat("\n\n")
}
portfolioRisk()

#----

##---- Cashflow

cashflow <- function() {

    ## Cashflow from bonds to meet requirements
    ## Cash requirement is found in vector b
    ## A contains the cashflow from 5 bonds

    library(lpSolve)
    numBonds <- 5
    prices <- c(104.76, 113.23, 83.29, 192.65, 87.78)

    A <- -1*matrix(cbind(c(1.5, 3, 3, 5, 3.5),
                         c(1.5, 3, 3, 5, 3.5),
                         c(1.5, 3, 3, 5, 3.5),
                         c(1.5, 3, 3, 5, 3.5),
                         c(101.5, 3, 5, 5, 3.5),
                         c(0, 103, 3, 5, 3.5),
                         c(0, 0, 103, 5, 3.5),
                         c(0, 0, 0, 105, 103.5)), byrow=T, ncol=5)
    b <- -1*c(1e4, 2e4, 1e4, 2e4, 5e4, 7e4, 3e4, 15e4)

    # constraint to integer solutions
    cashflow.lp <- lp(objective.in=prices, const.mat=A, const.rhs=b, const.dir=rep("<=", 8),
                int.vec=1:5)
    cashflow.lp$solution

}
cashflow()

#----

##---- Capital Budgeting

capitalBudgeting <- function() {

    ## cashflows contain the cashflows from the projects
    numProjects=8
    cashflows <- -1*c(50, 85, 43, 25, 94, 34, 840, 80)

    A <- matrix(cbind(c(30, 20, 20, 10, 40, 20, 20, 15),
                      # x3-x4 <= 0
                      # if you invest in 3 you invest in 4
                      c(0, 0, 1, -1, 0, 0, 0, 0),
                      # x2+x4 <=1
                      # either invest in 2 or 4
                      c(0, 1, 0, 1, 0, 0, 0, 0)), nrow=3, byrow=T)
    b <- c(100, 0, 1)

    capitalBudgeting.lp <- lp(objective.in=cashflows, const.mat=A, const.rhs=b, const.dir=c("<="),
                              binary.vec=1:numProjects)
    capitalBudgeting.lp$solution
}
capitalBudgeting()

#----
