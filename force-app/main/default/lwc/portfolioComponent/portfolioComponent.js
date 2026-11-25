import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class PortfolioComponent extends NavigationMixin(LightningElement) {
    @api portfolioData; 

    get hasPortfolioData() {
        return !!this.portfolioData;
    }

    handleViewResume() {
        // Implement logic to handle resume view (e.g., download, navigate to external URL)
        // For example:
        window.open('/path/to/resume.pdf', '_blank'); 
    }

    handleTrailheadClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://trailhead.salesforce.com/' 
            }
        });
    }

    handleYoutubeClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://www.youtube.com/@kumartech7' // Replace with your YouTube channel URL
            }
        });
    }

    handleLinkedInClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://www.linkedin.com/in/' // Replace with your LinkedIn profile URL
            }
        });
    }

    handleTwitterClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://twitter.com/' // Replace with your Twitter handle
            }
        });
    }
}