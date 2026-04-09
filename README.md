# npost

Flutter app with automated GitHub Pages deploy.

## GitHub Pages

The repository is configured to build the Flutter web app on every push to `main`
and publish the generated files to the `prod` branch.

GitHub Pages settings for this repository should use:

- Source: `Deploy from a branch`
- Branch: `prod`
- Folder: `/ (root)`

The expected Pages URL is:

- `https://mauriciosiqueira.github.io/Npost.Frontend/`

The workflow builds with:

- `flutter build web --release --base-href /Npost.Frontend/`

## Development

Install dependencies:

```bash
flutter pub get
```

Run locally:

```bash
flutter run
```
