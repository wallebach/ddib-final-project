// Network configuration for the Subscription Platform
const NETWORK_CONFIG = {
    local: {
        name: "Local Development",
        chainId: "0x7A69", // 31337 in hex
        rpcUrl: "http://127.0.0.1:8545",
        contracts: {
            STRToken: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
            GRNToken: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
            SubscriptionPlatform: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
            PlatformGovernance: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
        }
    },
    sepolia: {
        name: "Sepolia Testnet",
        chainId: "0xAA36A7", // 11155111 in hex
        rpcUrl: "https://eth-sepolia.g.alchemy.com/v2/bZdDtjJkRmOvawP-7o_5G",
        contracts: {
            STRToken: "0x476583dC4c957B8E08f665821b70475758968A47",
            GRNToken: "0xF73690E884058eCA52e2481ed4EbA371aD663d00",
            SubscriptionPlatform: "0xF45219516F11D62984241e3d36F758697647Cf8A",
            PlatformGovernance: "0x98b1C9Cf701800F68A1C4ECCe29c814CeA788114"
        }
    },
    fuji: {
        name: "Avalanche Fuji",
        chainId: "0xA869", // 43113 in hex
        rpcUrl: "https://avax-fuji.g.alchemy.com/v2/bZdDtjJkRmOvawP-7o_5G",
        contracts: {
            STRToken: "0x2095c816A8Ce50186fDEa58547cFBD16528adee8",
            GRNToken: "0x0fF3aD9f4306972127Dc6F76eD430846D4CB4c9b",
            SubscriptionPlatform: "0x476583dC4c957B8E08f665821b70475758968A47",
            PlatformGovernance: "0xF73690E884058eCA52e2481ed4EbA371aD663d00"
        }
    },
    uzh: {
        name: "UZH_ETH_PoS",
        chainId: "0x2C6", // 710 in hex
        rpcUrl: "http://rpc-uzheths.blockchain-group.ch:8546",
        contracts: {
            STRToken: "0x6520B205804909f5e6B8bf2647242bf4267603d9",
            GRNToken: "0x69C7c66dFB1C2b089b53D4474191F61225c6E0cf",
            SubscriptionPlatform: "0x8280b8D997aCedEe239Cd5C857e796969385268d",
            PlatformGovernance: "0xe24825cDE14e96e46f3B2640A2769f168009BaB2"
        }
    }
};

// Default network
let currentNetwork = 'local';

// Network switching utilities
const NetworkUtils = {
    getCurrentNetwork: () => currentNetwork,
    
    setNetwork: (network) => {
        if (NETWORK_CONFIG[network]) {
            currentNetwork = network;
            localStorage.setItem('selectedNetwork', network);
            ThemeUtils.applyTheme(network);
            return true;
        }
        return false;
    },
    
    getNetworkConfig: (network = currentNetwork) => NETWORK_CONFIG[network],
    
    getContractAddress: (contractName, network = currentNetwork) => {
        const config = NETWORK_CONFIG[network];
        return config ? config.contracts[contractName] : null;
    },
    
    initializeNetwork: () => {
        const savedNetwork = localStorage.getItem('selectedNetwork');
        if (savedNetwork && NETWORK_CONFIG[savedNetwork]) {
            currentNetwork = savedNetwork;
        }
    },
    
    switchNetwork: async (network) => {
        if (!NETWORK_CONFIG[network]) {
            throw new Error(`Network ${network} not configured`);
        }
        
        const config = NETWORK_CONFIG[network];
        
        try {
            // Request account access if needed
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            
            // Try to switch to the network
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: config.chainId }],
            });
            
            currentNetwork = network;
            localStorage.setItem('selectedNetwork', network);
            ThemeUtils.applyTheme(network);
            return true;
            
        } catch (switchError) {
            // This error code indicates that the chain has not been added to MetaMask
            if (switchError.code === 4902) {
                try {
                    await window.ethereum.request({
                        method: 'wallet_addEthereumChain',
                        params: [{
                            chainId: config.chainId,
                            chainName: config.name,
                            rpcUrls: [config.rpcUrl],
                            nativeCurrency: network === 'fuji' ? {
                                name: "AVAX",
                                symbol: "AVAX",
                                decimals: 18
                            } : network === 'uzh' ? {
                                name: "UZHETHs",
                                symbol: "UZHETHs",
                                decimals: 18
                            } : {
                                name: "ETH",
                                symbol: "ETH",
                                decimals: 18
                            }
                        }],
                    });
                    
                    currentNetwork = network;
                    localStorage.setItem('selectedNetwork', network);
                    return true;
                    
                } catch (addError) {
                    console.error('Failed to add network:', addError);
                    throw addError;
                }
            } else {
                console.error('Failed to switch network:', switchError);
                throw switchError;
            }
        }
    }
};

// Network theme colors
const NETWORK_THEMES = {
    local: {
        primary: '#6c757d',
        primaryHover: '#5a6268',
        primaryRgb: '108, 117, 125',
        name: 'Anvil (Gray)'
    },
    sepolia: {
        primary: '#1ce783',
        primaryHover: '#16c46e',
        primaryRgb: '28, 231, 131',
        name: 'Ethereum (Green)'
    },
    fuji: {
        primary: '#e84142',
        primaryHover: '#d73839',
        primaryRgb: '232, 65, 66',
        name: 'Avalanche (Red)'
    },
    uzh: {
        primary: '#a855f7',
        primaryHover: '#9333ea',
        primaryRgb: '168, 85, 247',
        name: 'UZH (Violet)'
    }
};

// Theme utilities
const ThemeUtils = {
    getCurrentTheme: () => NETWORK_THEMES[currentNetwork] || NETWORK_THEMES.local,
    
    applyTheme: (network = currentNetwork) => {
        const theme = NETWORK_THEMES[network];
        if (!theme) return;
        
        const root = document.documentElement;
        root.style.setProperty('--primary-color', theme.primary);
        root.style.setProperty('--primary-hover', theme.primaryHover);
        root.style.setProperty('--primary-rgb', theme.primaryRgb);
        
        // Apply dark theme for all networks
        root.style.setProperty('--container-background', 'rgba(28, 30, 42, 0.6)');
        root.style.setProperty('--container-accent', 'rgba(255, 255, 255, 0.05)');
        root.style.setProperty('--text-color', '#ffffff');
        root.style.setProperty('--text-color-secondary', '#b8bcc8');
        root.style.setProperty('--network-selector-bg', 'rgba(28, 30, 42, 0.8)');
        root.style.setProperty('--network-info-bg', 'rgba(255, 255, 255, 0.05)');
        root.style.setProperty('--border-color', 'rgba(255, 255, 255, 0.1)');
        root.style.setProperty('--input-bg', 'rgba(255, 255, 255, 0.1)');
        root.style.setProperty('--input-border', 'rgba(255, 255, 255, 0.2)');
        root.style.setProperty('--tab-bg', 'rgba(28, 30, 42, 0.6)');
        root.style.setProperty('--tab-hover-bg', 'rgba(255, 255, 255, 0.05)');
        
        // Apply dark background for all networks
        document.body.style.background = 'linear-gradient(135deg, #0b0d17 0%, #1c1e2a 100%)';
        document.body.style.color = '#ffffff';
        
        // Update any existing network info display
        const networkInfo = document.getElementById('networkInfo');
        if (networkInfo) {
            const config = NetworkUtils.getNetworkConfig(network);
            networkInfo.innerHTML = `<strong>Network:</strong> ${config.name} | <strong>Chain ID:</strong> ${config.chainId} | <strong>Theme:</strong> ${theme.name}`;
        }
    },
    
    initializeTheme: () => {
        ThemeUtils.applyTheme();
    }
};

// Initialize network and theme on load
NetworkUtils.initializeNetwork();
ThemeUtils.initializeTheme();