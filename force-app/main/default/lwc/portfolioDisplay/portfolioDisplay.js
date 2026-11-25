import { LightningElement, api } from 'lwc';

export default class PortfolioDisplay extends LightningElement {
    @api profilePhoto;
    @api userName;
    @api userTitle;
    @api userBio;
    @api skills = [];
    @api projects = [];
    @api resumeLink;
    @api trailheadLink;
    @api youtubeLink;
    @api linkedInLink;
    @api twitterLink;
}