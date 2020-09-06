const Swapper = artifacts.require("Swapper");
const IERC20 = artifacts.require("IERC20");

const toWei = web3.utils.toWei
const fromWei = web3.utils.fromWei

// this address has dai, must be unlocked using --unlock ADDRESS
const userAddress = '0x3dfd23a6c5e8bbcfc9581d2e864a68feb6a076d3'

async function execute() {
    const [ account ] = await web3.eth.getAccounts()
    const swapper = await Swapper.new(
        '0xA5407eAE9Ba41422680e2e00537571bcC53efBfD', // susd
        '0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51', // y
        '0x9a48bd0ec040ea4f1d3147c025cd4076a2e71e3e' // usdpp
    );
    const dai = await IERC20.at('0x6B175474E89094C44Da98b954EedeAC495271d0F'); // dai
    const tusd = await IERC20.at('0x0000000000085d4780B73119b644AE5ecd22b376'); // dai
    const usdpp = await IERC20.at('0x9a48bd0ec040ea4f1d3147c025cd4076a2e71e3e'); // usdpp
    const amount = toWei('100');
    await dai.transfer(account, amount, { from: userAddress });
    await dai.approve(swapper.address, amount);
    console.log({
        dai: fromWei(await dai.balanceOf(account)),
        tusd: fromWei(await tusd.balanceOf(account)),
        usdpp: fromWei(await usdpp.balanceOf(account))
    });
    const joinPool = await swapper.joinPool(toWei('90'), 1, amount, false, { gas: 2000000 })
    console.log({
        gasUsed: joinPool.receipt.gasUsed,
        dai: fromWei(await dai.balanceOf(account)),
        tusd: fromWei(await tusd.balanceOf(account)),
        usdpp: fromWei(await usdpp.balanceOf(account))
    });
}

module.exports = async function (callback) {
    try {
        await execute()
    } catch (e) {
        // truffle exec <script> doesn't throw errors, so handling it in a verbose manner here
        console.log(e)
    }
    callback()
}