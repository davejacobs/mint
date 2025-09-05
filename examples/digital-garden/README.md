# Digital Garden Example

This example demonstrates a nested digital garden structure focused on home decor and fashion, with files at various depths (1-3 levels deep).

## Structure

```
digital-garden/
├── index.md (root - "My Style Garden")
├── topics/
│   ├── home-decor/
│   │   ├── index.md (2 levels deep)
│   │   ├── living-room-concepts.md (2 levels deep)
│   │   └── styles/
│   │       ├── scandinavian-minimalism.md (3 levels deep)
│   │       └── bohemian-chic.md (3 levels deep)
│   └── clothing/
│       ├── index.md (2 levels deep)
│       ├── color-coordination.md (2 levels deep)
│       └── categories/
│           ├── sustainable-fashion.md (3 levels deep)
│           └── capsule-wardrobe.md (3 levels deep)
└── daily-notes/
    └── 2024/
        └── january-reflections.md (3 levels deep)
```

## Theme

The garden explores the intersection of home decor and personal style, with cross-references between related concepts like sustainability, color theory, and mindful curation.

## Testing Commands

Test with preserve-structure and navigation:

```bash
cd examples/digital-garden
mint publish --working-dir . --destination output --preserve-structure --navigation --navigation-title "My Style Garden" **/*.md
```

Test without preserve-structure:

```bash
cd examples/digital-garden
mint publish --working-dir . --destination output --navigation --navigation-title "My Style Garden" **/*.md
```