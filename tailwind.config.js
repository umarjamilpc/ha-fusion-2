/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	corePlugins: {
		preflight: false
	},
	theme: {
		extend: {
			fontFamily: {
				sans: ['"Inter Variable"', 'Inter', 'system-ui', 'sans-serif']
			},
			borderRadius: {
				glass: '1.125rem'
			},
			boxShadow: {
				glass:
					'0 4px 24px rgba(0, 0, 0, 0.28), inset 0 1px 0 rgba(255, 255, 255, 0.07)',
				'glass-active':
					'0 8px 36px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.12)'
			},
			transitionDuration: {
				glass: '240ms'
			}
		}
	},
	plugins: []
};
