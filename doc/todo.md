# todo

## 2025-04-23

- [ ] log ``link``, ``issue``, and ``journal`` solutions in style guide
- [ ] verify that item-created date-times are being logged in database
  - it's far more important than added-to-database date-time

## 2025-04-14

- [x] idea: journal table
  - solution
    - journals can be kept in a markdown doc
    - journals and items can be connected by create time
      - not by a database entry
    - journal needs special field
      - ``affected items: XXXX-XX-XX``
  - records scan jobs, etc

## 2025-04-10

- [x] idea: issue table
  - solution
    - issues can be kept in a markdown doc
    - issues and items can be connected by create time
      - not by a database entry
    - issue needs special field
      - ``affected items: XXXX-XX-XX``

## 2025-04-08

- [ ] consider
  - some of the latter items might need to be recollated
- [ ] idea: item size (pysical dimensions)
  - items will most likely be categorized by size
  - items as big as an index card that get scanned will probably be filed apart from the other papers
    - without me knowing in the future

## 2025-04-07

- papertrail
  - dev roadmap
    - [ ] batch-rename (*.pdf)
    - [ ] push to database
    - [ ] es.exe integration/cooperation
    - [ ] walk file
      - pdf viewer
      - edit window
        - column-based fields
    - [ ] timeline
    - [ ] whenami
    - [x] link table
    - [ ] column aliases
    - [ ] rename pssemstation to pspapertrail
  - note
    - the *.pdf version of each item is actually much smaller than its *.md conversion
    - consider
      - [ ] save the *.pdf version to external file store
      - [ ] rename all *.pdf items

## 2025-04-06

- [x] add ``link`` table
  - solution
    - links can be kept in a markdown doc
    - links and items can be connected by tag
      - not by a database entry
    - link needs special field: ``tag``
  - _many tags have many links_
- style and usage notes
  - [ ] moniker system
    - rather than keyword
  - [ ] narrowing method system
    - rather than definite structure
- [ ] ``from`` and ``physical``
- [ ] change ``arrival`` to ``received``
- [ ] partial dates (eg ``2007``, ``2018-05``)
- [ ] dbrequest type to wrap db manager calls
  - not quite a db connector; if I call it that, it will probably be embarrassing
- [ ] idea
  - "es could not find the file '...' on your device. Possible candidates include (using fzf)."
- [ ] consider: default order-by clause
- [x] rename batch type
- [x] sem pool
  - [x] sem pool
  - [x] accept 'sem get item' and 'sem find', etc as pipeline input
- [x] sem batch 0
- [x] sem pool .
- [x] sem pool 20250322025429.pdf, 20250322025449.pdf, 20250322025459.pdf
- [x] sem pool (dir ~/documents/temp/*.*)
- [x] sem tag budget, paystub
- [x] sem date 2025-02-02
- [x] sem reset
- [x] sem untag claim
- [x] sem undate 2025-02-01
- [x] sem commit
- [x] sem get tag
- [x] sem get date
- [x] sem get item
  - [x] sem get item
  - [x] accept 'sem get item' and 'sem find', etc as pipeline input
  - [x] with
    - [x] tag
      - [x] eq
      - [x] ne
        - [x] name | descript | content
          - [x] eq
          - [x] ne
          - [x] like
          - [x] notlike
          - [x] match
          - [x] notmatch
        - [x] date
          - [x] eq
          - [x] ne
          - [x] after
          - [x] before
          - [x] between
  - [x] created | arrived | expiry
    - [x] eq
    - [x] ne
    - [x] after
    - [x] before
    - [x] between
- [ ] sem find

---

[← Go Back](../readme.md)

