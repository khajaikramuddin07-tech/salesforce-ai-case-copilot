import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import analyzeCase from '@salesforce/apex/AICaseService.analyzeCase';
import getLatestInteraction from '@salesforce/apex/AICaseService.getLatestInteraction';
import saveAgentDecision from '@salesforce/apex/AICaseService.saveAgentDecision';

export default class AiCaseAssistant extends LightningElement {
    @api recordId;

    interaction;
    recommendation;
    editedResolution = '';
    editedResponse = '';
    errorMessage = '';
    isBusy = false;
    wiredInteractionResult;

    @wire(getLatestInteraction, { caseId: '$recordId' })
    wiredInteraction(result) {
        this.wiredInteractionResult = result;
        if (result.data) {
            this.applyInteraction(result.data);
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get confidenceLabel() {
        if (!this.interaction?.confidence && this.interaction?.confidence !== 0) {
            return '';
        }
        return `Confidence ${Math.round(this.interaction.confidence * 100)}%`;
    }

    get hasKnowledge() {
        return (this.recommendation?.knowledgeReferences || []).length > 0;
    }

    get hasSimilarCases() {
        return (this.recommendation?.similarCases || []).length > 0;
    }

    async handleAnalyze() {
        this.errorMessage = '';
        this.isBusy = true;
        try {
            await analyzeCase({ caseId: this.recordId });
            this.toast('Analysis queued', 'The AI recommendation request is processing.', 'success');
            await refreshApex(this.wiredInteractionResult);
        } catch (error) {
            this.errorMessage = this.reduceError(error);
            this.toast('Unable to analyze case', this.errorMessage, 'error');
        } finally {
            this.isBusy = false;
        }
    }

    handleResolutionChange(event) {
        this.editedResolution = event.target.value;
    }

    handleResponseChange(event) {
        this.editedResponse = event.target.value;
    }

    async handleAccept() {
        await this.saveDecision('Accepted');
    }

    async handleEdit() {
        await this.saveDecision('Edited');
    }

    async handleReject() {
        await this.saveDecision('Rejected');
    }

    async saveDecision(decision) {
        if (!this.interaction?.id) {
            return;
        }

        this.isBusy = true;
        const feedback = JSON.stringify({
            resolution: this.editedResolution,
            customerResponse: this.editedResponse
        });

        try {
            const updated = await saveAgentDecision({
                interactionId: this.interaction.id,
                decision,
                feedback
            });
            this.applyInteraction(updated);
            this.toast('Decision saved', `Recommendation ${decision.toLowerCase()}.`, 'success');
        } catch (error) {
            this.errorMessage = this.reduceError(error);
            this.toast('Unable to save decision', this.errorMessage, 'error');
        } finally {
            this.isBusy = false;
        }
    }

    applyInteraction(interaction) {
        this.interaction = interaction;
        this.errorMessage = interaction?.errorMessage || '';
        this.recommendation = this.parseRecommendation(interaction?.recommendationJson);
        this.editedResolution = this.recommendation?.recommendedResolution || '';
        this.editedResponse = this.recommendation?.draftCustomerResponse || '';
    }

    parseRecommendation(value) {
        if (!value) {
            return null;
        }

        try {
            return JSON.parse(value);
        } catch (error) {
            this.errorMessage = 'The AI recommendation could not be parsed.';
            return null;
        }
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unexpected error.';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
