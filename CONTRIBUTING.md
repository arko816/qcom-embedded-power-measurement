## Contributing to Qualcomm Embedded Power Measurement (QEPM)

Hi there!

We are thrilled that you would like to contribute to this project.
Your help is essential for keeping this project useful and making it better.

## Branching Strategy

In general, contributors should develop on branches based on `main`, and pull requests should be made against `main`.

## Submitting a pull request

1. Read the [code of conduct](CODE-OF-CONDUCT.md) and [license](LICENSE).

2. [Fork](https://github.com/qualcomm/qcom-embedded-power-measurement/fork) and clone the repository.

   ```bash
   git clone https://github.com/<username>/qcom-embedded-power-measurement.git
   ```

3. Create a new branch based on `main`.

   ```bash
   git checkout -b <my-branch-name> main
   ```

4. Add the public repository as an upstream remote.

   ```bash
   git remote add upstream https://github.com/qualcomm/qcom-embedded-power-measurement.git
   ```

5. Make your changes, add tests, and verify that the relevant builds and tests pass.

6. Commit your changes using the [DCO](http://developercertificate.org/). You can attest to the DCO using the `-s` or `--signoff` option, or by manually adding a `Signed-off-by` line.

   ```bash
   git commit -s -m "Describe the change"
   ```

7. Synchronize your topic branch with upstream `main`.

   ```bash
   git pull --rebase upstream main
   ```

8. Push to your fork.

   ```bash
   git push -u origin <my-branch-name>
   ```

9. [Submit a pull request](https://github.com/qualcomm/qcom-embedded-power-measurement/pulls) from your branch to `main`.

10. Wait for review and address feedback.

## Contribution guidance

- Use GitHub issues to report bugs, propose features, or discuss architecture changes.
- Document changes that alter supported behavior.
- Follow [LLVM coding conventions](https://llvm.org/docs/CodingStandards.html) for new code where practical.
- Add or update tests.
- Keep each change focused.
- Use clear commit messages.
- Discuss large changes with maintainers before implementation.