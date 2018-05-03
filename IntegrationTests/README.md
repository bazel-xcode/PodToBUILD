# PodToBUILD output testing system

## Adding a new example:

First Download the podspec

```
wget https://raw.githubusercontent.com/FolioReader/FolioReaderKit/master/FolioReaderKit.podspec
```

Check in the IPC json version under Goldmaster

```
pod ipc spec FolioReaderKit.podspec 2>&1 | cat > Examples/FolioReaderKit.podspec.json
```

Update the current output

```
make goldmaster
```
