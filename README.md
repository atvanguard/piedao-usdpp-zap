# Mint PieDAO USD++ with a single underlying coin

1. Compile
```
npm run compile
```

2. Run Mainnet ganache fork
```
ganache-cli --fork https://mainnet.infura.io/v3/<INFURA_PROJECT_ID> --unlock 0x3dfd23a6c5e8bbcfc9581d2e864a68feb6a076d3 --unlock 0x6B175474E89094C44Da98b954EedeAC495271d0F
```

3. Test
```
truffle exec scripts/test.js
```