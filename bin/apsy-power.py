#!/usr/bin/env python3
"""apsy-power — required-sample-size / power computation for common designs.

Grounds the FORMULATE power-analysis step in real computation rather than a guess. Uses statsmodels
when available; otherwise falls back to a normal-approximation for the two-sample t-test and reports
which path was used. Prints a result line plus a small sensitivity table.

Usage:
  apsy-power.py --test t2     --effect 0.5  [--alpha 0.05] [--power 0.8] [--ratio 1] [--tail two]
  apsy-power.py --test paired --effect 0.4
  apsy-power.py --test corr   --effect 0.3
  apsy-power.py --test prop2  --effect 0.1  --p1 0.5
  apsy-power.py --test anova  --effect 0.25 --groups 3
"""
import argparse, math, sys


def z(p):
    # inverse normal CDF (Acklam approximation) — avoids a scipy dependency
    a = [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
         1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
    b = [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
         6.680131188771972e+01, -1.328068155288572e+01]
    c = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
         -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
    dd = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
          3.754408661907416e+00]
    plow, phigh = 0.02425, 1 - 0.02425
    if p < plow:
        q = math.sqrt(-2 * math.log(p))
        return (((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) / ((((dd[0]*q+dd[1])*q+dd[2])*q+dd[3])*q+1)
    if p <= phigh:
        q = p - 0.5; r = q*q
        return (((((a[0]*r+a[1])*r+a[2])*r+a[3])*r+a[4])*r+a[5])*q / (((((b[0]*r+b[1])*r+b[2])*r+b[3])*r+b[4])*r+1)
    q = math.sqrt(-2 * math.log(1 - p))
    return -(((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) / ((((dd[0]*q+dd[1])*q+dd[2])*q+dd[3])*q+1)


def n_per_group_normal_approx(d, alpha, power, tail="two"):
    za = z(1 - alpha/2) if tail == "two" else z(1 - alpha)
    zb = z(power)
    return math.ceil(2 * ((za + zb) / d) ** 2)


def compute(args):
    try:
        from statsmodels.stats.power import (TTestIndPower, TTestPower,
                                             FTestAnovaPower, NormalIndPower)
        sm = True
    except Exception:
        sm = False

    test = args.test
    notes = []
    if test in ("t2", "paired"):
        if sm:
            alternative = "two-sided" if args.tail == "two" else "larger"
            if test == "t2":
                analysis = TTestIndPower()
                n = analysis.solve_power(effect_size=args.effect, alpha=args.alpha,
                                         power=args.power, ratio=args.ratio,
                                         alternative=alternative)
                per = "per group"
            else:   # paired — TTestPower.solve_power() does NOT accept 'ratio'
                analysis = TTestPower()
                n = analysis.solve_power(effect_size=args.effect, alpha=args.alpha,
                                         power=args.power, alternative=alternative)
                per = "pairs"
            n = math.ceil(n)
        else:
            n = n_per_group_normal_approx(args.effect, args.alpha, args.power, args.tail)
            per = "per group (normal approx)" if test == "t2" else "pairs (normal approx; ~per group)"
            notes.append("statsmodels not installed — used normal approximation; install statsmodels for exact power.")
        return n, per, notes
    if test == "corr":
        # Fisher z transform
        if abs(args.effect) >= 1:
            return None, "", ["correlation effect must be |r|<1"]
        za = z(1 - args.alpha/2); zb = z(args.power)
        zr = 0.5 * math.log((1 + args.effect) / (1 - args.effect))
        n = math.ceil(((za + zb) / zr) ** 2 + 3)
        return n, "total", notes
    if test == "prop2":
        p1 = args.p1; p2 = p1 + args.effect
        if not (0 < p1 < 1 and 0 < p2 < 1):
            return None, "", ["p1 and p1+effect must be in (0,1)"]
        za = z(1 - args.alpha/2); zb = z(args.power)
        pbar = (p1 + p2) / 2
        n = math.ceil(((za*math.sqrt(2*pbar*(1-pbar)) + zb*math.sqrt(p1*(1-p1)+p2*(1-p2))) / (p2-p1))**2)
        return n, "per group", notes
    if test == "anova":
        if sm:
            n = math.ceil(FTestAnovaPower().solve_power(effect_size=args.effect, alpha=args.alpha,
                                                        power=args.power, k_groups=args.groups))
            return n, "per group", notes
        notes.append("ANOVA power needs statsmodels — not installed.")
        return None, "", notes
    return None, "", [f"unknown test '{test}'"]


def main():
    ap = argparse.ArgumentParser(description="Required-N / power for common designs.")
    ap.add_argument("--test", required=True, choices=["t2", "paired", "corr", "prop2", "anova"])
    ap.add_argument("--effect", type=float, required=True, help="d (t-tests), r (corr), diff (prop2), f (anova)")
    ap.add_argument("--alpha", type=float, default=0.05)
    ap.add_argument("--power", type=float, default=0.8)
    ap.add_argument("--ratio", type=float, default=1.0)
    ap.add_argument("--tail", choices=["two", "one"], default="two")
    ap.add_argument("--p1", type=float, default=0.5, help="baseline proportion (prop2)")
    ap.add_argument("--groups", type=int, default=3, help="k groups (anova)")
    args = ap.parse_args()

    n, per, notes = compute(args)
    if n is None:
        print("ERROR: " + "; ".join(notes), file=sys.stderr); sys.exit(1)
    print(f"Required N = {n} {per}  (test={args.test}, effect={args.effect}, alpha={args.alpha}, power={args.power})")
    print("\nSensitivity (required N vs power):")
    for pw in (0.70, 0.80, 0.90, 0.95):
        a2 = argparse.Namespace(**{**vars(args), "power": pw})
        nn, pp, _ = compute(a2)
        print(f"  power={pw:.2f} -> N={nn} {pp}")
    for note in notes:
        print(f"\nNote: {note}")


if __name__ == "__main__":
    main()
